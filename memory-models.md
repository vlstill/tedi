---
vim: wrap linebreak nolist formatoptions-=t
---

The behavior of a program in presence of relaxed memory is described by relaxed memory model.
The relevant memory model depends on the programming language of choice (as it can allow reordering of certain actions for the purpose of optimizations) and on the hardware on which the program is running.
It also depends on the compiler (or interpreter or virtual machine) which is responsible for translating the program in a way that it meets the guarantees given in the specification of the programming language.
We will abstract from the impact of the compiler and expect it to be correct in most of our considerations.
We will also abstract from the impact of an operating system's scheduler which can move program threads between physical processing units, which could be visible in memory behavior, but the operating system should make sure this effect is not visible.

In the hardware, there are two main sources for the relaxed memory behavior, both of them caused by the fact that the memory is several orders of magnitude slower than the processor.
One of these sources is the cache hierarchy, which tries to hide speed differences by storing parts of the data in caches.
The other is out-of-order execution which further improves speed by reordering the instructions and issuing instructions speculatively.

Depending on the implementation of these optimizations, different relaxations are observable.
On `x86` only store buffering (delaying of propagation of writes to the memory) is observable, while on ARM or POWER reordering of all kinds of instructions is observable, as is branch prediction.
A more detailed description of causes for memory relaxations (mainly originating from cache hierarchies) can be found in \cite{hw_view_for_sw_hackers}.
All processors with relaxed memory also provide instructions which allow the programmer to constrain relaxations: memory fences (or barriers) which prevent reordering and atomic instructions such as atomic compare-and-swap or atomic read-modify-write.

When dealing with the memory model of the hardware, it is usually neither possible nor useful to discuss the behavior of the concrete CPU, instead, we discuss the behavior of a certain platform (e.g. Intel `x86` or IBM POWER).
There are at least two good reasons for this: first, results which take into account only the concrete CPU might not be applicable to any other CPU, even from the same family, and second, the exact architecture is usually kept secret by the company manufacturing those CPUs.
For this reason, hardware memory models describe processor platforms and should over-approximate behavior of processors of given platform and capture intend of hardware designers to allow the results to remain relevant even for future processors.
The over-approximation might be also needed to simplify the memory model in order to make the subsequent program analysis simpler.

Ideally, formalized memory models of hardware would be produced by the hardware manufactures themselves, but this is not the case.
Instead, these memory models of contemporary platforms are usually created based on informal descriptions provided by the manufacturers, empirical testing of existing hardware, and discussion with the manufacturers \cite{x86tso, Sarkar2011, Flur2016}.

Alternatively, one might describe a memory model of a programming language (or compiler, if the programming language in question does not define memory behavior of parallel programs).
This would then allow analysis of the program to reason about its behavior on any platform for which it can be compiled (assuming the compiler is correct).
Sadly, similar to CPU platforms, programming languages usually lack a precise formal description of the memory model, see e.g. \cite{cppmemmod} for analysis of draft of C++11 memory model.
Furthermore, such specifications can be unnecessarily strict for some cases: for example, according to C++11, any parallel programs in which two threads communicate without presence of locks or atomic operations has an undefined behavior and therefore can have arbitrary outcome, but in practice communication using volatile variables (and possibly compiler specific memory fences) can work well with most compilers and is often used in legacy code written before C++11 (or C11 in the case of C) where there was no support for concurrency in the language.

In the following sections, we will first look into ways to describe memory models formally (\autoref{sec:semantics}).
Then we will inspect important memory models of hardware and programming languages (\autoref{sec:models}).
Finally, we will shortly discuss the impact of compiler optimizations on memory models (\autoref{sec:compilers}).

# Description of Memory Model Semantics {#sec:semantics}

As already noted, it is often the case that CPU architecture specifications or language specifications describe memory models informally.
This can lead to imprecision when such specification is used as a basis for a program, compiler or analyzer implementation.
For this reason, it is useful to have formal semantics given to memory models.

Two main options used for the description of memory model semantics are an axiomatic semantics which is usually based on dependency relations between actions of the program, and operational semantics which describes working of an abstract machine which implements given memory model.

## Axiomatic Semantics

The axiomatic semantics of a memory model usually builds on relations between various memory related actions of the program and properties of these relations.
These relations are mostly partial orders and a sequence of operations usually adheres to a memory model if a union of memory-model-specific subset of these relations is acyclic (i.e. is a partial order).
There are several notations for describing axiomatic semantics which mostly differ in the names of defined relations and in some details in the description.
The framework presented in \cite{Alglave2010_fences} aims at description of different memory models in a unified way by a set of common dependency relations.
In our figures, we will borrow some notation from this framework, namely the *program order relation* (\rel{po}) which orders actions performed by a single thread, the *read-from* relation (\rel{rf}) which connects a read with the store that saved the loaded value, and the *from-read* relation (\rel{fr})[^fr] which connects read with the nearest store after the one read (i.e. with the store which will overwrite the read value).
Furthermore, the *write serialization* relation (\rel{ws})[^ws] is notable for describing the guarantee given by all reasonable memory models: for each memory location there is a single total order of all writes to this location.
That is, writes to a single location has to be observed in the same order by all the threads.
Other relations will be introduced as needed in the figures.

[^fr]: In other works also *conflict relation*.
[^ws]: In other works also *coherence relation*.

## Operational Semantics

Alternativelly, description of memory models can use operational semantics.
Operational semantics describes behavior of a program in terms of its run on an abstract machine, i.e. by describing the mechanisms which cause memory relaxations (usually in a largely simplified way which should closely match behavior of the real hardware, but might use very different mechanisms).
This usually makes operational semantics easier to understand by programmers and hardware designers and also can lead to more direct implementation of certain analysis techniques.

## Other Ways of Description of Memory Models

There are also some works which use different frameworks to describe memory models.

In \cite{Arvind2006} memory models are described in terms of two properties: allowed instruction reordering and *store atomicity*.
Store atomicity roughly states that there is a global interleaving of all possibly reordered operations and the authors suggest that it is a desirable property of a memory model.
Nevertheless, most architectural memory models lack store atomicity -- both SPARC memory models (TSO/PSO/RMO) and `x86`-TSO allow loads to be satisfied from store buffer, making stores observable in the issuing thread before they can be observed in other threads; POWER further allows independent stores to become visible in different order in different threads.

The semantics given in \cite{PichonPharabod2016} is based on event structures \cite{event_structures} and considers all runs of the program at once.
It is intended to allow reasoning about compiler optimizations.
Due to its global view of the program, it is not clear if it can be used for efficient analysis of larger programs.

# Formalized Memory Models {#sec:models}

In this section we describe commonly used and formalized memory models.
These memory models are usually derived from hardware or programming language memory models.
In older works, most notable memory models (apart from Sequential Consistency) were memory models of the SPARC processors.
These processors can be configured for different memory models (given in order from most strict to most relaxed): Total Store Order (TSO), Partial Store Order (PSO), Relaxed Memory Order (RMO) \cite{SPARC94}.
Later memory models include Non-Speculative Writes (NSW) memory model which is more relaxed then PSO but less relaxed then RMO and is notable because reachability problem of programs with finite state processes under NSW is decidable while for RMO this problem is not decidable, which makes this memory models significant even if it does not describe any hardware implementation.
Further significant memory models include the `x86` (and `x86-64`) memory model formalized as `x86`-TSO, POWER and ARM memory models, and memory models of certain programming languages, namely Java (Java was the first mainstream programming language with defined memory model), C#, and C/C++11.

## Sequential Consistency {#sec:sc}

Under sequential consistency all memory actions are immediately globally visible and therefore can be ordered by a total order (i.e. an execution of parallel program is an interleaving of actions of its threads) \cite{Lamport1979}.
Furthermore, each load returns the last value written to its memory location in this total order.
In the operational semantics, SC corresponds to machine without any caches and buffers where every write is immediately propagated to the global memory and every read reads directly from the memory.
SC is the most intuitive and strongest memory model and it is often used by program analysers, but it is not used in most modern hardware.
There are no fences in SC as it has no need for them.

## Total Store Order {#sec:tso}

Total Store Order (TSO) was introduced in the context of SPARC processors \cite{SPARC94}.
It allows reordering of writes with following reads originating from the same thread.
Also, the thread that invokes a read can read value from a program-order-preceding write even if this write is not globally visible yet.

Operational semantics can be described by a machine which has an unbounded, processor-local FIFO store buffer in each processor.
Writes are stored into the store buffer in the order in which they are executed.
If a read occurs, the processor first consults its local store buffer and if it contains an entry for the loaded address it reads newest such entry.
If there is no such entry in the local store buffer, the value is read from the memory.
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

The memory model used by `x86` and `x86-64` processors is basically TSO with different fences and atomic instructions then in the SPARC implementation.
The memory model is described informally in Intel and AMD specification documents and a formal semantics derived from these documents and experimental evaluation is described in the `x86`-TSO memory model \cite{x86tso}.
The semantics of `x86`-TSO is formalized in HOL4 model and as an abstract machine.

On top of stores and loads which behave as under the TSO memory model, `x86` has fence instructions, a family of read-modify-write instructions, and a compare-exchange instruction.

## Partial Store Order {#sec:pso}

Partial Store Order (PSO) is similar to TSO and also introduced by the SPARC processors \cite{SPARC94}.
On top of TSO relaxations it allows reordering of pairs of writes which do not access the same memory location.
Operational semantics corresponds to a machine which has separate store buffer for each memory location.
Again, processor can read from its local store buffers, but values saved in these buffers are invisible for other processors \cite{SPARC94}.
PSO-mode SPARC processors include barriers for restoration of TSO as well as SC \cite{SPARC94}.
An example for PSO-allowed run which is not TSO-allowed can be found in \autoref{fig:pso}.

This memory model is supported for example by SPARC in PSO mode, but this is not a common architecture and configuration \cite{SPARC94, hw_view_for_sw_hackers}, which means this memory model is mostly important theoretically.

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
Please note that there is control flow dependency between `c` and `d` and therefore they cannot be executed in inverted order under PSO.
\end{caption}
\label{fig:pso}
\end{figure}

## Non-Speculative Writes {#sec:nsw}

The Non-Speculative Writes (NSW) memory model was introduced in \cite{Atig2012} as a memory model which is more relaxed then PSO, but its reachability problem for programs with finite state threads is still decidable.
The operation model for NSW is also defined in \cite{Atig2012}.
It uses two levels of store buffers and a memory history buffer for reordering of reads.

On top of PSO relaxations, NSW allows reordering of reads with other reads and it is defined with read-read and write-write fences and atomic read-modify-write instructions.
We show example of NSW behaviour which is not allowed by PSO in \autoref{fig:nsw}.
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
The write fence is not necessary, if it was not present the two threads would still not be able to observe different results under PSO, but it is used to demonstrate read reordering more clearly.
The fence gives rise to the \rel{ab} relation.
\end{caption}
\label{fig:nsw}
\end{figure}

## Relaxed Memory Order {#sec:rmo}

The relaxed memory order (RMO) further relaxes NSW by allowing all pairs of memory operations to be reordering provided they don't access the same memory location \cite{SPARC94}.
Operational semantics for RMO usually allows instruction reordering in the machine, or involves guessing loaded value at the point of the load instruction and validating the guess later.

RMO is supported by SPARC processors, examples of other hardware architectures with RMO-like memory models are POWER, ARM, and Alpha \cite{hw_view_for_sw_hackers}.

## POWER Memory Model

POWER is a very weak, RMO-like memory model in which it is possible to observe out-of-order execution as well as various effects of multi-level caches and cache coherence protocols \cite{Sarkar2011, Mador-Haim2012}.
For example, POWER allows independent writes to be propagated to different threads in different orders, or loads to be executed before control flow dependent loads (i.e. a load after a branch can be executed before the load which determines if the branch will be taken; this is not possible for writes).
An example of POWER-allowed behavior can be found in \autoref{fig:power}.

The semantics of POWER processors is specified, apart from vendor documents, in both operational and axiomatic formalizations.
In \cite{Sarkar2011} POWER 7 memory model is described in form of an abstract machine: it is an operational semantics, nevertheless, it is rather complicated due to subtleties of the architecture.
This description was later extended in \cite{Sarkar2012} to support POWER's load-reserve/store-conditional instructions which are used to implement low-level primitives such as compare-and-swap and atomic read-modify-write.
An axiomatic semantics of POWER 7 is given in \cite{Mador-Haim2012} and also in \cite{Alglave2010_fences}.
Nevertheless, \cite{Sarkar2011} observes that while being in agreement with experimental results, \cite{Alglave2010_fences} is not matching architectonic intend as well as their operational semantic.
To our best knowledge, there is no formal description of the newer POWER 8 or POWER 9 architectures.

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
An example of behavior allowed by POWER, but not by NSW.
There are 4 threads, two of them writing one of `x` and `y`.
The remaining two threads read these variables, but observe their updates in inverted order (i.e. the third thread first reads new value of `x` and then old value of `y`, therefore it observes `x` first, but the last thread observes new value of `y` and then old value of `x`).
The read fences do not help in this case, as the two writes happen in independent threads an therefore are not ordered in any way with respect to each other (the fences are used only to distinguish from NSW).
The \rel{ab} relation is created by the fences.
\end{caption}
\label{fig:power}
\end{figure}

## ARM Memory Model

The ARM memory model is similar to the POWER memory model, also exposing effects of out-of-order execution and cache hierarchy \cite{Flur2016}.
Nevertheless, there are important distinctions between ARM and POWER, both from the point of observable relaxations as well as hardware causes for this relaxations.
It was formalized operationally in \cite{Flur2016}, building upon the same principles as the operational model for POWER introduced in \cite{Sarkar2011}.
This operational model describes the latest ARMv8/AArch64 64bit architecture and the work compares it to the POWER 7 architecture.
There is also an older axiomatic model of ARMv7 given in \cite{Alglave2014}.

## Memory Models of Programming Languages {#sec:langs}

Modern programming languages often acknowledge importance of parallelism and define memory behavior of concurrent programs.
Some programming languages give guarantees that programs which correctly use locks for synchronization observe sequentially consistent behavior (the *data race free guarantee*).
This holds for example for Java \cite{Aspinall2007} and for the fragment of C++ without atomics weaker then sequentially consistent \cite{Turon2014} \cite[\$1.10.21]{isocpp11draft}.
On top of that, some programming languages, such as C, C++, and Java provide support for atomic operations which can be used for synchronization without locks if the platform they are running on supports it.
C and C++ also support lower-level atomic operations with relaxed semantics which can be faster on platforms with relaxed memory.

### C and C++

In C and C++ prior to the 2011 standards, there was no support for threads and shared memory parallelism in the language.
In these times creators of parallel programs were dependent on platform and compiler specific libraries and primitives, e.g. the `pthread` library for threading and `__sync_*` family of functions for atomic operations in the GCC and Clang compilers.

The C++11 and C11 standards introduced support for threading and atomic operations to these languages.
From the point of relaxed memory models, the interesting part of this is the support for atomic operations and fences.

The atomic operation library provides support for declaration of atomic variables which can be used in atomic operations, such as loads, stores, atomic read-modify-write, and compare-exchange.
For any atomic operation, it is possible to specify the required ordering: C/C++ allows not only sequentially consistent atomic operations, but also weaker (low-level) atomic operations which allows implementation of efficient parallel data structures in platform-independent way.

The C++ memory model is not formalized in C++11 standard, an attempt to formalize it was given in \cite{cppmemmod}, formalizing the N3092 draft of the standard \cite{N3092}.
While this formalization precedes the final C++11 standard, it seems that there were no changes in the specification of atomic operations after N3092.
Nevertheless, there are some differences between the formalization and N3092 (which are justified in the paper).

A notable feature of the C++ memory model is that any program which contains a data race on non-atomic variable[^race] has undefined behavior. This means that synchronization is possible only by atomic variables and concurrency primitives such as mutexes and condition variables.

[^race]: Data race is defined as two accesses to the same non-atomic variable, at least one of them write, which are not synchronized so that they cannot happen concurrently.

### LLVM

The LLVM compiler infrastructure \cite{LLVM} used by the clang compiler comes with its own low-level programming language.
The LLVM memory model is derived from the C++11 memory model, with the difference that it lacks release-consume ordering and offers additional *Unordered* ordering which does not guarantee atomicity but makes results of data races defined \cite{llvm:langref}.
The *Unordered* operations are intended to match semantics of Java memory model for shared variables \cite{llvm:langref}.

### Java

The Java memory model is rather different from the C++11 one.
Its primary goal is to ensure that programs which cannot observe data races under sequential consistency will execute as if running under sequential consistency (the data race free guarantee) \cite{javamm_popl_Manson2005}.
The primary means of synchronization in Java are mutexes (called monitors in Java), synchronized sections of code (which use monitors internally), and volatile variables, which roughly correspond to sequentially consistent atomics in C++11.

Furthermore, as Java strives to be memory safe, it also defines behavior of programs with data races.
This behavior is rather peculiar, as it is primarily concerned with prohibiting *out-of-this-air* values -- values which, informally speaking, depend cyclically on themselves.
These values are primarily prohibited to avoid forging pointers to invalid memory or memory which should be otherwise inaccessible to a given thread \cite{javamm_popl_Manson2005}.

#### Out-of-Thin-Air Values

The problem with out-of-thin-air values is that it is sometimes hard to draw a line between behavior in which value occurs as a result of well established compiler optimization and where it undesirably occurs out of pure speculation.
To that end \cite{javamm_popl_Manson2005} uses a definition which is based on *justifying executions* -- a kind of inductive definition in which more relaxed executions are iteratively built from less relaxed executions.
While this semantics intended to allow wide range of optimizations, it later turned out that it disallows certain reasonable optimizations \cite{Cenciarelli2007, Sevcik2008, Torlak2010}.

Indeed the task of disallowing out-of-thin-air values while allowing optimizations is hard and there is no consensus on this topic.
For example, the C++11 memory model allows these behaviors, but at the same time states that implementations are discouraged to exhibit them \cite{cppmemmod}.
The framework for for description of hardware memory models introduced in \cite{Alglave2010_fences} disallows out-of-thin-air values based on data and control dependencies.
This is too strict for use in programming language memory model as these dependencies are changed by optimizers.
It might be acceptable for hardware memory models where dependencies are more explicit and no current hardware exhibits this behavior, but \cite{Flur2016} mentions that this behavior is intentionally left allowed by the ARMv8 memory model, in accordance with intends of the hardware architects.
An alternative specification of semantics which aims at avoiding this problem was shown in \cite{PichonPharabod2016}, proposing new formalization of fragment of C++11.

# Memory Models and Compilers {#sec:compilers}

When analysing programs in high level programming languages (as opposed to analysing assembly level programs), there can be substantially more relaxation then allowed by the memory model of the hardware these programs target.
The reason is that compilers are allowed to perform optimizations which reorder code or eliminate unnecessary memory accesses.
As a result, a compiler can for example merge two loads from a non-atomic variable or assume a load which follows a store to the same memory location to yield the stored value.
Further reordering is allowed as per-thread program order is not a total order for programs in languages such as C and C++ (e.g. order of evaluation of function arguments is not fixed by the standard in most cases).

These optimizations complicate analysis if they should be taken into account.
The two basic options for their handling include reasoning about all permitted reordering (see e.g. \cite{PichonPharabod2016}), or side stepping the problem by using the same optimizing compiler to produce code both for verification and for actual execution (e.g. by verifying the binary or optimized intermediate representation of the compiler).
