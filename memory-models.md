---
vim: wrap linebreak nolist formatoptions-=t
---

The behavior of a program in presence of relaxed memory is described by relaxed memory model.
The relevant memory model depends on the programming language of choice (as it can allow reordering of certain actions for the purpose of optimizations) and on the hardware on which the program is running.
It also depends on the compiler (or interpreter or virtual machine) which is responsible for translating the program in a way that it meets the guarantees given in the specification of the programming language.
We will, however, abstract from the impact of the compiler and expect it to be correct in most of our considerations.
We will also abstract from the impact of an operating system's scheduler which can move program threads between physical processing units, which could be visible in memory behavior, but the operating system should make sure this effect is not visible.

When dealing with the memory model of the hardware, it is usually neither possible nor useful to discuss the behavior of the concrete CPU, instead, we discuss the behavior of a certain platform (e.g. Intel `x86` or POWER).
There are at least two good reasons for this: first, results which take into account only the concrete CPU might not be applicable to any other CPU, even from the same family, and second, the exact architecture is usually kept secret by the company manufacturing those CPUs.
Sadly, the second problem also partially applies to descriptions of the behavior of CPU platforms: relaxed memory behavior is usually described by informal documents and not by a formal specification and therefore is open to misinterpretation.
Some of these problems can be found for example in the description of the `x86` memory model (x86-TSO) \cite{x86tso}.
Furthermore, even when we have a formal description of the behavior of a certain platform, this description usually over-approximates possible behaviors of the program.
For example, no reasonable platform can delay arbitrary number of memory writes, but the x86-TSO memory model allows it as the bound on such reordering is unknown.

Alternatively, one might describe a memory model of a programming language (or compiler, if the programming language in question does not define memory behavior of parallel programs).
This would then allow analysis of the program to reason about its behavior on any platform for which it can be compiled (assuming the compiler is correct).
The disadvantage is that, similar to CPU platforms, programming languages usually lack a precise formal description of the memory model, see e.g. \cite{cppmemmod} for analysis of draft of C++11 memory model.
Furthermore, such specifications can often be unnecessarily strict: for example, according to C++11, any parallel programs in which two threads communicate without presence of locks or atomic operations has an undefined behavior and therefore can have arbitrary outcome, but in practice communication using volatile variables (and possibly compiler specific memory fences) can work well with most compilers and is often used in legacy code written before C++11 (or C11 in the case of C) where there was no support for concurrency in the language.

In the following sections, we will first look into hardware constructs which give rise relaxed memory (\autoref{sec:hw}), then, in \autoref{sec:semantics} we will introduce two possibilities of precise characterization of memory models, namely an axiomatic approach based on relations between memory actions of the program and an operational model.
In \autoref{sec:models} we will then describe common formally-defined memory models and their relation to hardware or language memory models.
Finally in \autoref{sec:compilers} we will discuss the impact of compiler optimizations on memory models.

# Hardware View of Memory Relaxation {#sec:hw}

In order to understand certain characteristics of relaxed memory models, it is useful to know what hardware constructs give rise to memory relaxation and why they are used.

As the memory is significantly slower that the CPU, the CPU contains cache memories which can store part of the information in the main memory in the way which makes the access faster \cite{TODO}. In modern CPUs, there are usually multiple levels of cache memory, often two or three, some of which are local to a CPU core and some might be shared among several cores of the CPU \cite{TODO}. If multiple threads work with the same memory it is important they have a consistent view of the memory, even if the values are cached in different caches. To achieve this cache consistency, CPUs employ cache coherence protocols and memory relaxations arise from optimizations of these protocols \cite{hw_view_for_sw_hackers}.

For example, to avoid the need to write values directly to the memory or at least wait for other processors to acknowledge the new value, processors use store buffers which can hold written values before the propagation is completed.
The observable effect of store buffers is that writes can appear to be executed after loads which occur after them in code.
Furthermore, if the processor has multiple store buffers (for different memory locations), writes to different memory memory location can be observed in different order then they are executed.

Reordering of reads after writes and of different writes can be caused by invalidation queues or by instruction reordering due to out-of-order execution. Some platforms (\TODO{such as Alpha}) can even exhibit reordering of dependent instructions (e.g. pointed-to value can be loaded before the pointer value).

To make programming possible under these relaxations, processors provide various techniques to constrain relaxations.
These techniques include memory fences which prevent reordering of certain classes of instructions and atomic instructions which can be used to implement some operations (such as fetch-and-add, compare-and-swap) atomically.

# Description of Memory Model Semantics {#sec:semantics}

As already noted, it is often the case that CPU architecture specifications or language specifications describe memory models informally.
This, however, can lead to imprecision when such specification is used for as a basis for a program, compiler or analyzer implementation.
For this reason, it is useful to have formal semantics given to memory models.

Two main options are used for the description of memory model semantics, an axiomatic semantics usually based on dependency relations between actions of the program, and operational semantics which describes working of an abstract machine which implements the given memory model.

## Axiomatic Semantics

The axiomatic semantics of memory models usually builds on relations between various (memory related) actions of the program and properties of these relations.
These relations are mostly partial orders and a sequence of operations usually adheres to a memory model if a union of memory-model-specific subset of these relations is a partial order (i.e. is acyclic).
There are several notations for describing axiomatic semantics which mostly differ in the names of defined relations and in some detains in the description.
Some of them are used to describe a particular memory model \cite{…; …}.
The framework presented in \cite{Alglave2010_fences} is more general and aims at description of different memory models in a unified way by a set of common dependency relations.
In our figures, we will borrow some notation from \cite{Alglave2010_fences}, namely the *program order relation* (\rel{po}) which orders actions performed by a single thread, the *read-from* relation (\rel{rf}) which connects a read with the store which saved the loaded value, and the *from-read* relation (\rel{fr}) which connects read with the nearest store after the one read (i.e. with the store which will overwrite the read value).
Other relations will be introduced as needed in the figures.

### The Problem of Out of Thin Air Reads {#sec:thin}

The notion of out of thin air reads was \TODO{probably} introduced by the Java memory model \cite{javamm_Gosling2005, javamm_popl_Manson2005}.
The idea is that a value produced by a read must not depend on itself.
They are excluded from the Java memory models as they could allow creation of invalid pointers, effectively destroying any memory safety guarantees.
Other programming languages, such as C and C++ allow them in their memory model, mostly in order not to disallow important optimizations (the C++ standard also states that no implementation should actually exhibit this behavior)
Some formal memory model descriptions, such as \cite{Alglave2010_fences}, explicitly forbid out-of-thin air reads, while other allow them (e.g. the formalization of C++ memory model in \cite{cppmemmod}).

See \autoref{fig:thin:naive} for example of out of thin air read.

\begin{figure}[tp]

\begin{subfigure}[t]{\textwidth}
\begin{threads}{3}
\begin{thread}

```{.cpp}
r1 = x; // a
y = r1; // b
```

\end{thread}
\begin{thread}

```{.cpp}
r2 = y; // c
x = r2; // d
```

\end{thread}
\begin{thread}
\begin{tikzpicture}[semithick]
    \node (a) {\texttt{a}};
    \node[below = of a] (b) {\texttt{b}};
    \node[right = of a] (c) {\texttt{c}};
    \node[below = of c] (d) {\texttt{d}};

    \drawrel{a}{b}{dp};
    \drawrel[right]{c}{d}{dp};
    \drawrel{d}{a}{rf};
    \drawrel[right]{b}{c}{rf};
\end{tikzpicture}
\end{thread}
\end{threads}

\noindent
Reachable `x == 1 && y == 1`?

\begin{caption}
An example of out of thin air reads.
Suppose both `x` and `y` are initialized to 0, the question is if it is possible that at the end are both `x` and `y` equal to 1.
\end{caption}
\label{fig:thin:naive}
\end{subfigure}

\begin{subfigure}[t]{\textwidth}
\bigskip
\begin{threads}{3}
\begin{thread}

```{.cpp}
r1 = x;        // a
if ( r1 == 1 )
    y = r1;    // b
```

\end{thread}
\begin{thread}

```{.cpp}
r2 = y;        // c
if ( r2 == 1 )
    x = 1;     // d1
else
    x = 1;     // d2
```

\end{thread}
\begin{thread}
\begin{tikzpicture}[semithick]
    \node (a) {\texttt{a}};
    \node[below = of a] (b) {\texttt{b}};
    \node[right = 4em of a] (c) {\texttt{c}};
    \node[below = of c] (d) {\texttt{d1} + \texttt{d2}};

    \drawrel{a}{b}{dp};
    \drawrelgray[right]{c}{d}{po};
    \drawrel{d}{a}{rf};
    \drawrel[right]{b}{c}{rf};
\end{tikzpicture}
\end{thread}
\end{threads}

\noindent
Reachable `r1 == 1 && r2 == 1`?

\begin{caption}
Example of program which exhibits thin air reads if we consider them to be defined by syntactical dependency, but not if we consider them defined by semantical dependency (statements `d1` and `d2` can be merged and their `if` removed which allows reordering of `c` with the merged statement).
Note that \rel{po} is considered not to be preserved by the memory model, therefore it is gray.
\end{caption}
\label{fig:thin:deps}

\end{subfigure}
\begin{caption}
Illustration of out of thin air reads and related dependency problems. \rel{dp} denotes the dependency relation.
\end{caption}
\end{figure}

Sadly, there seems to be no widely agreed-upon definition of out of thin air reads \cite{relaxed_opt_semantics_no_thin}.
Even in the aforementioned definition, the problem is that the dependency relation is not clearly defined -- if it is defined as syntactical dependency, that excluding thin air reads prohibits certain important optimizations.
Indeed \cite{Sevcik2008} shows that there are commonly used optimizations which are forbidden by the Java memory mode.
Furthermore, restricting the dependencies to semantic dependencies does not solve the problem efficiently as these are hard to compute as they are not properties of a single run of a program: in \autoref{fig:thin:deps}, it can be seen that while the write of `1` to `x` in the `then` branch of thread 2 is syntactically dependent on the load of `y`, it is not semantically dependent and indeed if the optimizer merged the two branches of the `if` and removed the `if` the write would become independent of the read.

As this behaviour is especially important for programming languages because of optimizations which often do not preserve syntactic dependencies.
On the level of assembly languages or machine code, syntactic dependencies usually coincide with notion of dependencies as seen by the processor.
For this reason, disallowing thin air reads is well justified and practical if reasoning on the level of assembly instructions (where it is in agreement with current hardware which does not exhibit out thin air reads).

An alternative semantics that aims at avoiding semantical out of thin air reads while allowing optimizations is provided in \cite{relaxed_opt_semantics_no_thin}.

## Operational Semantics

Alternativelly, description of memory models can use operational semantics.
Operational semantics describes behavior of a program in terms of its run on an abstract machine, i.e. by describing the mechanisms which cause memory relaxations (usually in a largely simplified way which should closely match behavior of the real hardware).
This usually makes operational semantics easier to understand by programmers and also can lead to more direct implementation of analysis techniques.

## Other Ways of Description of Memory Models

There are also some works which use different frameworks to describe memory models.

In \cite{Arvind2006} memory models are described in terms of two properties: allowed instruction reordering and *store atomicity*.
Store atomicity roughly states that there is global interleaving of all possibly reordered operations and the authors suggest that it is a desirable property of a memory model.
Nevertheless, most architectural memory models lack write atomicity -- both SPARC memory models (TSO/PSO/RMO) and `x86`-TSO allow loads to be satisfied from store buffer, making stores observable in the issuing thread before they can be observed in other threads; POWER further allows independent stores to become visible in different order in different threads.
The paper describes the proposed memory model in term of partial ordering among events in the program and also suggests procedure for generation of all allowed runs of the program.

The semantics given in \cite{relaxed_opt_semantics_no_thin} is based on event structures \cite{event_structures} and considers all runs of the program at once.
It is intended to allow reasoning about compiler optimizations.
Due to its global view of the program, it is not clear if it can be used for effective analysis of larger programs.

# Formally Defined Memory Models {#sec:models}

In this section we will describe commonly used and formalized memory models.
These memory models are usually derived from hardware or programming language memory models.
In older works, most notable memory models (apart from Sequential Consistency) were memory models of the SPARC processors which can be configured for different memory models (in order from most strict to most relaxed): Total Store Order (TSO), Partial Store Order (PSO), Relaxed Memory Order (RMO) \cite{SPARC94}.
Later memory models include Non-Speculative Writes (NSW) memory model which is more relaxed then PSO but less relaxed then RMO and is notable because reachability problem of programs with finite state processes under NSW is decidable while for RMO this problem is not decidable, which makes this memory models significant even if it does not describe any hardware implementation.
Further significant memory models include the `x86` (and `x86-64`) memory model formalized as `x86`-TSO, POWER and ARM memory models, and memory models of certain programming languages, namely Java (Java was the first mainstream programming language with defined memory model), C#, and C/C++11.

## Sequential Consistency {#sec:sc}

Under sequential consistency all memory actions are immediately globally visible and therefore can be ordered by a total order (i.e. an execution of parallel program is an interleaving of actions of its threads).
Furthermore, there are no fences as SC has no need for them.
In the operational semantics, this corresponds to machine without any caches and buffers where every write is immediately propagated to the global memory and every read reads directly from the memory.
This is the most intuitive and strongest memory model and it is often used by program analysers, but it is not used in most modern hardware.

## Total Store Order {#sec:tso}

Total Store Order (TSO) was introduced in the context of SPARC processors \cite{SPARC94}.
It allows reordering of writes with following reads originating from the same thread that access different memory locations.
Also, the thread that invokes a read can read value from a program-order-preceding write even if this write is not globally visible yet.

Operational semantics can be described by a machine which has an unbounded, processor-local FIFO store buffer in each processor.
Writes are stored into the store buffer in the order in which they are executed.
If a read occurs, the processor first consults its local store buffer and it it contains an entry for the loaded address it reads newest such entry.
If there is no entry in the local store buffer, the value is read from the memory.
An any point the oldest value from the store buffer can be removed from the buffer and stored to the memory.
This way the writes in the store buffer are visible only to the processor which issued them until they are (non-deterministically) flushed to the memory.
Machines which implement TSO-like memory models will usually provide memory barriers which flush the store buffer \cite{hw_view_for_sw_hackers, x86tso}.

An example of TSO-allowed run which is not allowed under SC can be found in \autoref{fig:tso}.

\begin{figure}[tp]
\begin{threads}{3}

\begin{thread}

```{.cpp}
x = 1;  // a
r1 = y; // b
```

\end{thread}
\begin{thread}

```{.cpp}
y = 1;  // c
r2 = x; // d
```

\end{thread}
\begin{thread}
\begin{tikzpicture}[semithick, minimum height = 1.7em]
    \node (ix) {init \texttt{x}};
    \node[right = of ix] (iy) {init \texttt{y}};
    \node[below = 0.5em of ix](a) {\texttt{a}};
    \node[below = 1em of a] (b) {\texttt{b}};
    \node[below = 0.5em of iy] (c) {\texttt{c}};
    \node[below = 1em of c] (d) {\texttt{d}};

    \drawrelgray{a}{b}{po};
    \drawrelgray[right]{c}{d}{po};
    \drawrel{b}{iy}{rf};
    \drawrel[right]{d}{ix}{rf};
\end{tikzpicture}
\end{thread}
\end{threads}

\noindent Reachable `r1 == 0 && r2 == 0`?
\begin{caption}
This code demonstrates behavior which is allowed under TSO but is not allowed under SC.
In this run `x = 1` is executed first, but the store is buffered and does not reach memory yet.
Then `r1 = y` is executed, reading value 0 from `y`.
Then the second thread is executed fully, and since the update of `x` was not yet propagated to the memory it reads 0 from `x`.
Finally, the update of `x` (originating from `a`) is performed.
\end{caption}
\label{fig:tso}
\end{figure}

## `x86`-TSO: `x86` and `x86-64` Processors

The memory model used by `x86` and `x86-64` processors is basically TSO with different fences and atomic instructions.
The memory model is described informally in Intel and AMD specification documents \cite{TODO, TODO}.
Formal semantics derived from these documents and experimental evaluation was given in \cite{x86tso} in form of the `x86`-TSO memory model.
The semantics of `x86`-TSO is formalized in HOL4 model and as an abstract machine.

On top of stores and loads which behave as under the TSO memory model, `x86` has fence instructions, a family of read-modify-write instructions, and a compare exchange instruction.

## Partial Store Order {#sec:pso}

Partial Store Order (PSO) is similar to TSO and also introduced by the SPARC processors \cite{SPARC94}.
On top of TSO relaxations it allows reordering of pairs of writes which do not access the same memory location.
Operational semantics corresponds to a machine which has separate store buffer for each memory location.
Again, processor can read from its local store buffers, but values saved in these buffers are invisible for other processors \cite{SPARC94}.
PSO-mode SPARC processors include barriers for restoration of TSO as well as SC \cite{SPARC94}.
An example for PSO-allowed run which is not TSO-allowed can be found in \autoref{fig:pso}.

This memory model is supported for example by SPARC in PSO mode, but this is not
a common architecture and configuration \cite{SPARC94, hw_view_for_sw_hackers}, which means this memory model is mostly important theoretically.

\begin{figure}[tp]
\begin{threads}{3}
\begin{thread}

```{.cpp}
x = 1; // a
g = 1; // b
```

\end{thread}
\begin{thread}

```{.cpp}
while (!g) {} // c
r1 = x;       // d
```

\end{thread}
\begin{thread}
\begin{tikzpicture}[semithick, minimum height = 1.7em]
    \node(a) {\texttt{a}};
    \node[below = of a] (b) {\texttt{b}};
    \node[right = of a] (c) {\texttt{c}};
    \node[below = of c] (d) {\texttt{d}};
    \node[right = 1.6em of c] (ix) {init \texttt{x}};

    \drawrelgray{a}{b}{po};
    \drawrel[right]{c}{d}{dp};
    \drawrel[above right]{b}{c}{\ \;rf};
    \drawrel[right]{ix}{d}{rf};
    \drawrel[above left]{d}{a}{fr\ \,\,};
\end{tikzpicture}
\end{thread}
\end{threads}

\noindent Reachable `r1 == 0`?
\begin{caption}
This code demonstates behavior prohibited by TSO but allowed by PSO.
In this case, the second thread waits for a guard `g` to be set and then attempts to read `x`.
However, under PSO, writes to `x` and `g` can be reordered, resulting in action `d` reading from the initial value of `x`.
Please note that there is control flow dependency between `c` and `d` and therefore they cannot be executed in inverted order.
\end{caption}
\label{fig:pso}
\end{figure}

## Non-Speculative Writes {#sec:nsw}

The non-speculative writes memory model was introduced in \cite{Atig2012} as a memory model which is more relaxed then PSO, but its reachability problem for programs with finite state threads is still decidable.
The operation model for NSW is also defined in \cite{Atig2012}.
It uses two levels of store buffers and a history buffer for reordering of reads.

On top of PSO relaxations, NSW allows reordering of reads with other reads and it is defined with read-read and write-write fences and atomic read-modify-write instructions.
We show example of NSW behaviour which is not allowed by PSO in \autoref{fig:nsw}.
This memory model is proven to not allow causal cycles (which result in out-of-thin-air values).
There are probably no processors which use NSW memory model -- it is important theoretically for its decidability proofs.

\begin{figure}[tp]
\begin{threads}{4}
\begin{thread}

```{.cpp}
x = 1; // a
write_fence();
y = 1; // b
```

\end{thread}
\begin{thread}

```{.cpp}
r1 = x; // c
r2 = y; // d
```

\end{thread}
\begin{thread}

```{.cpp}
r3 = y; // e
r4 = x; // f
```

\end{thread}
\end{threads}

\bigskip

\noindent Reachable `r1 == 1 && r2 == 0 && r3 == 1 && r4 == 0`?

\begin{tikzpicture}[semithick, minimum height = 1.7em]

    \node (c) {\texttt{c}};
    \node[right = of c] (a) {\texttt{a}};
    \node[below = of a] (b) {\texttt{b}};
    \node[right = of a] (e) {\texttt{e}};
    \node[below = of c] (d) {\texttt{d}};
    \node[below = of e] (f) {\texttt{f}};

    \node[above right = of f] (ix) {init \texttt{x}};
    \node[above left = of d] (iy) {init \texttt{y}};
    \drawrel{a}{b}{ab};
    \drawrelgray[above left]{c}{d}{po};
    \drawrelgray[above right]{e}{f}{po};
    \drawrel{iy}{d}{rf};
    \drawrel{ix}{f}{rf};
    \drawrel[below]{a}{c}{rf};
    \drawrel[above right]{b}{e}{\ \;rf};
    \drawrel[above left]{f}{a}{fr\ \,\,};
    \drawrel[above]{d}{b}{fr};
\end{tikzpicture}

\begin{caption}
An example for behaviour allowed by NSW but not allowed by PSO.
While the two writes are well ordered, the corresponding reads are not and since the memory model relaxes read-read ordering they can observe values in different order.
The write fence is not necessary, if it would not be present the two threads would still not be able to observe different results under PSO, but it is used to demonstrate that read reordering more clearly.
The fence gives rise to the \rel{ab} relation.
\end{caption}
\label{fig:nsw}
\end{figure}

## Relaxed Memory Order {#sec:rmo}

The relaxed memory order (RMO) further relaxes NSW by allowing all pairs of memory operations to be reordering provided they don't access the same memory location.
Operational semantics for RMO usually involves guessing loaded value at the point of the load instruction and validating the guess later.
A relaxation not allowed under NSW but allowed under RMO is demonstrated by the example in \autoref{fig:rmo}.

Examples of hardware architectures with RMO-like memory models are POWER, ARM, and Alpha \cite{hw_view_for_sw_hackers}.

\begin{figure}[tp]
\begin{threads}{4}
\begin{thread}

```{.cpp}
x = 1; // a
```

\end{thread}
\begin{thread}

```{.cpp}
y = 1; // b
```

\end{thread}
\begin{thread}

```{.cpp}
r1 = x; // c
read_fence();
r2 = y; // d
```

\end{thread}
\begin{thread}

```{.cpp}
r3 = y; // e
read_fence();
r4 = x; // f
```

\end{thread}
\end{threads}

\bigskip

\noindent Reachable `r1 == 1 && r2 == 0 && r3 == 1 && r4 == 0`?

\begin{tikzpicture}[semithick, minimum height = 1.7em]

    \node (c) {\texttt{c}};
    \node[above right = 1.5em of c] (a) {\texttt{a}};
    \node[right = of a] (b) {\texttt{b}};
    \node[below right = 1.5em of b] (e) {\texttt{e}};
    \node[below = of c] (d) {\texttt{d}};
    \node[below = of e] (f) {\texttt{f}};

    \node[above right = of f] (ix) {init \texttt{x}};
    \node[above left = of d] (iy) {init \texttt{y}};

    \drawrel{c}{d}{ab};
    \drawrel{e}{f}{ab};
    \drawrel{iy}{d}{rf};
    \drawrel[right]{ix}{f}{rf};
    \drawrel{a}{c}{rf};
    \drawrel[right]{b}{e}{rf};
    \drawrel[right]{f}{a}{fr};
    \drawrel{d}{b}{fr};
\end{tikzpicture}

\begin{caption}
An example of behavior allowed by RMO, but not by NSW .
There are 4 threads, two of them writing one of `x` and `y`.
The remaining two threads read these variables, but observe their updates in inverted order (i.e. the third thread first reads new value of `x` and then old value of `y`, therefore it observes `x` first, but the last thread observes new value of `y` and then old value of `x`).
The read fences do not help in this case, as the two writes happen in independent threads an therefore are not ordered in any way with respect to each other (the fences are used only to distinguish from NSW).
The \rel{ab} relation is created by the fences.
\end{caption}
\label{fig:rmo}
\end{figure}

## POWER Memory Model

POWER is a very weak, RMO-like memory model in which it is possible to observe out-of-order execution as well as various effects of multi-level caches and cache coherence protocols \cite{Sarkar2011}.
For example, POWER allows independent writes to be propagated to different threads in different orders, or loads to be executed before control flow dependent loads (i.e. a load after a branch can be executed before the load which determines if the branch will be taken; this is not possible for writes).
An example of POWER-allowed behavior can be found in \cite{fig:power}.
The semantics of POWER processors is specified in numerous vendor documents \cite{TODO} and there are also some formalizations, such as \cite{Sarkar2011} which formalizes POWER 7 architecture and its predecessors (while being more over-approximative for the predecessors).
The semantics presented in \cite{Sarkar2011} is given in a form of an abstract machine: it is an operational semantics, nevertheless, it is rather complicated due to subtleties of the architecture.
An axiomatic semantic of POWER is given in \cite{Alglave2010_fences}, although \cite{Sarkar2011} observes that it while being in agreement with experimental results, it is not matching architectonic intend as well as their operational semantic.
To our best knowledge, there is no formal description of the newer POWER 8 or POWER 9 architectures.

## ARM Memory Model

# Memory Models of Programming Languages {#sec:langs}

Modern programming languages often acknowledge importance of parallelism and define memory behavior of concurrent programs.
In general, most programming languages give guarantee that programs which correctly use locks for synchronization observe sequentially consistent behavior \TODO{tohle by chtělo nějak podložit}.
On top of that, some programming languages, such as C, C++, and Java provide support for atomic operations which can be used for synchronization without locks if the platform they are running on supports it.
C and C++ also support lower-level atomic operations with relaxed semantics which can be faster on platforms with relaxed memory.

## C and C++

In C and C++ prior the 2011 standards there was no support for threads and shared memory parallelism in the language.
In these times creators of parallel programs were dependent on platform and compiler specific libraries and primitives, e.g. the `pthread` library for threading and `__sync_*` family of functions for atomic operations in the GCC compiler.

The C++11 and C11 standards introduced support for threading and atomic operations to these languages.
From the point of relaxed memory models, the interesting part of this is the support for atomic operations and fences.

The atomic operation library provides support for declaration of atomic variables which can be used in atomic operations, such as loads, stores, atomic read-modify-write, and compare-exchange.
For any atomic operation, it is possible to specify the required ordering: C/C++ allows not only sequentially consistent atomic operations, but also weaker (low-level) atomic operations which allows implementation of efficient parallel data structures in platform-independent way.

The C++ memory model is not formalized in C++11 standard, an attempt to formalize it was given in \cite{cppmemmod}, formalizing the N3092 draft of the standard \cite{N3092}.
While this formalization precedes the final C++11 standard, it seems[^cppmemmodvs11] that there were no changes in the specification of atomic operations after N3092.
Nevertheless, there are some differences between the formalization and N3092 (which are justified in the paper).

[^cppmemmodvs11]: \TODO{According to the clang compiler's C++ status page \cite{clangstatus} the documents defining semantics of C++ memory model and atomic instructions precede the N3092 draft.}

## Java

## LLVM

The LLVM compiler infrastructure \cite{LLVM} used by the clang compiler comes with its own low-level programming language.
The LLVM memory model is derived from the C++11 memory model, with the difference that it lacks release-consume ordering and offers additional *Unordered* ordering which does not guarantee atomicity but makes results of data races defined (while in C/C++ data races on non-atomic locations yield the entire run of the program undefined) \cite{llvm:langref}.
The *Unordered* operations are intended to match semantics of Java memory model for shared variables \cite{llvm:langref}.

# Memory Models and Compilers {#sec:compilers}

When analysing programs in high level programming languages (as opposed to analysing assembly level programs), there can be substantially more relaxation then allowed by the memory model of the hardware these programs target.
The reason is that compilers are allowed to perform optimizations which reorder code or eliminate unnecessary memory accesses.
This is allowed as program order for programs in languages such as C++ is not a total order even if restricted to one thread (e.g. order of evaluation of function arguments is not fixed by the standard in most cases).
As a result, a compiler can for example merge two loads from a non-atomic variable or assume a load which follows a store to the same memory location to yield the stored value.

These optimizations complicate analysis if they should be taken into account.
The two basic options for their handling include reasoning about all permitted reordering (see e.g. \cite{relaxed_opt_semantics_no_thin}), or side stepping the problem by using the same optimizing compiler to produce code both for verification and for actual execution (e.g. by verifying the binary or optimized intermediate representation of the compiler).
