---
vim: wrap linebreak nolist formatoptions-=t
---

The behavior of a program in presence of relaxed memory is described by relaxed memory model.
The relevant memory model depends on the programming language of choice (as it can allow reordering of certain actions for the purpose of optimizations) and on the hardware on which the program is running.
It also depends on the compiler (or interpreter or virtual machine, depending on the programming language of choice) which is responsible for translating the program in a way that it meets the guarantees given in the specification of the programming language.
We will, however, abstract from the impact of the compiler and expect it to be correct in most cases.
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
Furthermore, such specifications can often be unnecessarily strict: for example, according to C++11, any parallel programs in which two threads communicate without presence of locks or atomic operations has an undefined behavior and therefore can have arbitrary outcome, but in practice communication using volatile variables (and possibly compiler specific memory fences) can work well with most compilers and is often used in legacy code written before C++11 (or C11 in the case of C).

In the following sections, we will first look into hardware constructs which give rise relaxed memory (\autoref{sec:hw}), then, in \autoref{sec:semantics} we will introduce two possibilities of precise characterization of memory models, namely an axiomatic approach based on relations between memory actions of the program and an operational model.
In \autoref{sec:models} we will then describe common formally-defined memory models and their relation to hardware or language memory models.
Finally in \autoref{sec:compilers} we will discuss the impact of compiler optimizations on memory models.

# Hardware View of Memory Relaxation {#sec:hw}


In order to understand certain characteristics of relaxed memory models, it is useful to know what hardware constructs give rise to memory relaxation and why they are used.

As the memory is significantly slower that the CPU, the CPU contains cache memories which can store part of the information in the main memory in the way which makes the access faster \cite{TODO}. In modern CPUs, there are usually multiple levels of cache memory, often two or three, some of which are local to a CPU core and some might be shared among several cores of the CPU \cite{TODO}. If multiple threads work with the same memory it is important they have a consistent view of the memory, even if the values are cached in different caches. To achieve this cache consistency, CPUs employ cache coherence protocols and memory relaxations arise from optimizations of these protocols \cite{hw_view_for_sw_hackers}.

\TODO{…}

\TODO{atomic instructions}

# Description of Memory Model Semantics {#sec:semantics}

As already noted, it is often the case that CPU architecture specifications or language specifications describe memory models informally.
This, however, can lead to imprecision when such specification is used for as a basis for a program, compiler or analyzer implementation.
For this reason, it is useful to have formal semantics given to memory models.

Two main options are used for the description of memory model semantics, an axiomatic semantics usually based on dependency relations between actions of the program, and operational semantics which describes working of an abstract machine which implements the given memory model.

## Axiomatic Semantics

The axiomatic semantics of memory models builds on relations between various (memory related) actions of the program and properties of these relations.
We will mostly use the framework presented in \cite{Alglave2010_fences} which classifies several dependency relations (some of which are memory model dependent) and for each memory model, a union of some of these relations needs to be acyclic.

Following \cite{Alglave2010_fences} we now introduce relations between memory operations. All these relations are partial orders.
We will denote reads by $r$ ($r_1, r_2, …$), writes by $w$ ($w_1, w_2, …$), and arbitrary memory operations by $m$ ($m_1, m_2…$).
A read or write can also be part of atomic read-modify-write operation.

Program order
~   $m_1 \rel{po} m_2$, is a total order of actions performed by one processor (or thread).
    It never relates actions from different threads.
    Some instructions might consist of multiple memory accesses which are ordered according to their intra-instruction dependencies (e.g. the `lock xadd` `x86` instruction performs first a read and then a write that are ordered by \rel{po} \cite{x86tso}).

Dependencies
~   $r \rel{dp} m$, represents data and control dependencies between instructions, it is a subrelation of \rel{po} and its source is always a read.

Location program order
~   $m_1 \rel{po-loc} m_2$, is a restriction of \rel{po} in which $m_1$ and $m_2$ has to access the same memory location.

Preserved program order
~   $m_1 \rel{ppo} m_2$, is a subrelation of \rel{po} which is preserved by the given memory model (e.g. \tso does not preserve $w \rel{po} r$ pairs for different memory locations, \pso also does not preserve $w \rel{po} w$ pairs \cite{sparcmanual}).

Read-from map
~   $w \rel{rf} r$, links a write to a read which reads its value.
    For each read $r$ there is a unique write $w$ such that $w \rel{rf} r$.

External read-from map
~   $w \rel{rfe} r$, is a subrelation of \rel{rf} which links only events from distinct threads.

Internal read-from map
~   $w \rel{rfi} r$, is a subrelation or \rel{rf} which links only events the same thread.

Global read-from
~   $w \rel{grf} r$, is a subrelation of \rel{rf} which is preserved by a given memory model.

Write serialization
~   $w_1 \rel{ws} w_2$, is a total order on writes to the same memory location (i.e. the order in which writes become visible to all threads).
    \TODO{Often also denoted as ?coherence order?}

From-read map
~   $r \rel{fr} w$, denotes that $r$ reads from a write which precedes $w$ immediately in \rel{ws}.
    \TODO{Often also denoted as ?conflict relation?}
    It can be defined as $r \rel{fr} w \stackrel{def}{=} \exists w'.
    w' \rel{rf} r \land w' \rel{ws} w$.

Barrier ordering
~   $m_1 \rel{ab} m_2$, is ordering introduced by memory barriers (fences). It depends on the fence instructions of the platform and therefore on the memory model.

Global happens-before
~   $m_1 \rel{ghb} m_2$, is a union of relations which are global. \rel{ws} and \rel{fr} are always included in \rel{ghb}.
    \rel{ppo}, \rel{grf}, and \rel{ab} are also included, but their definition depends on the memory model.
    That is, $\rel{ghb} \stackrel{def}{=} \rel{ppo} \cup \rel{ws} \cup \rel{fr} \cup \rel{grf} \cup \rel{ab}$.

In this framework, the memory model is given by the choice of the relations defining \rel{ghb}. In all cases, there are three constraints which must be met.

\rel{ghb} must be acyclic
~   this corresponds to the fact that it (partially) orders actions of the program.

Memory coherence of each location must be respected
~   i.e. $\rel{po-loc} \cup \rel{rf} \cup \rel{ws} \cup \rel{fr}$ must be acyclic.

No *out of thin air* values
~   i.e. $\rel{rf} \cup \rel{dp}$ must be acyclic. The idea behind this is that values cannot depend on themselves.
    However, while common hardware architectures do not exhibit thin air reads, some theoretical memory models allow them (e.g. the memory model of C++11 \cite{cppmemmod, cpp11}).
    A larger discussion of the problem of thin air reads follows shortly.

This classification now allows us to decide the validity of an execution under a given memory model: we must classify ordering between actions of this execution and check that these relations follow the three constraints mentioned above.

### The Problem of Out of Thin Air Reads {#sec:thin}

The notion of out of thin air reads was \TODO{probably} introduced by the Java memory model \cite{javamm_Gosling2005, javamm_popl_Manson2005}. The idea is that a value produced by a read must not depend on itself. See \autoref{fig:thin:naive} for example of out of thin air read. The motivation for exclusion of thin air reads from Java is that they could allow creating invalid pointers, effectively destroying memory safety guarantees of Java. 

\begin{figure}[tp]

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
An example of out of thin air reads -- suppose both `x` and `y` are initialized to 0, the question is if it is possible that at the end are both `x` and `y` equal to 1. Now if we disregarded the out of thin air condition, it would be possible to build execution where $a \rel{rf} d$ and $c \rel{rf} b$ allowing arbitrary value to appear in `x` and `y`. Therefore the goal configuration would be reachable (provided \rel{po} and \rel{dp} are not preserved). To our best knowledge, no common hardware architecture can have this behavior.
\end{caption}
\label{fig:thin:naive}
\end{figure}

Sadly, there seems to be no widely agreed-upon definition of out of thin air reads \cite{relaxed_opt_semantics_no_thin}. Even in the aforementioned definition, the problem is that the dependency relation \rel{dp} is not clearly defined -- if it is \TODO{as usually} defined as syntactical dependency, that excluding thin air reads prohibits certain important optimizations. Indeed there are commonly used optimizations which are forbidden by the Java memory model \cite{Sevcik2008}. Furthermore, restricting the dependencies to semantic dependencies does not solve the problem efficiently as these are hard to compute and indeed are not properties of a single run of a program. In \autoref{fig:thin:deps}, it can be seen that while the write of `1` to `x` in the `then` branch of thread 2 is syntactically dependent on the load of `y`, it is not semantically dependent and indeed if the optimizer merged the two branches of the `if` and removed the `if` the write would become independent of the read.

\begin{figure}[tp]

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
Example of program which exhibits thin air reads if we consider them to be defined by syntactical dependency, but not if we consider them defined by semantical dependency (as statements `d1` and `d2` can be merged and their `if` removed which allows reordering of `c` with merged `d1` + `d2`). Note that \rel{po} is considered not to be preserved by the memory model, therefore it is gray.
\end{caption}
\label{fig:thin:deps}
\end{figure}

This problem is especially important for programming languages because of optimizations which often do not preserve syntactic dependencies. On the level of assembly languages or machine code, syntactic dependencies usually coincide with notion of dependencies as seen by the processor. For this reason, the thin air condition is well justified and practical if reasoning about instructions, but not when reasoning about high level code in a programming language.

For example, out of thin air reads are not prohibited by the C11 and C++11 standards even though these standards also state that implementations should not exhibit such behaviors (which is in agreement with current hardware which does not exhibit out thin air reads).

An alternative semantics that aims at avoiding semantical out of thin air reads while allowing optimizations is provided in \cite{relaxed_opt_semantics_no_thin}. This semantics is based on event structures \cite{event_structures} and therefore considers all runs of the program at once. For this reason it is not clear if it can be used for effective analysis of larger programs.

## Operational Semantics

The operational semantics describes behavior of a program in terms of its run on an abstract machine. \TODO{…}


# Formally Defined Memory Models {#sec:models}

In this section we will describe commonly used and formalized memory models.
These memory models are usually derived from hardware or programming language memory models.
In older works, most notable memory models (apart from Sequential Consistency) were memory models of the SPARC processors which can be configured for different memory models (in order from most strict to most relaxed): Total Store Order (TSO), Partial Store Order (PSO), Relaxed Memory Order (RMO) \cite{sparcmanual}.
Later memory models include Non-Speculative Writes (NSW) memory model which is more relaxed then PSO but less relaxed then RMO and is notable because reachability problem of programs with finite state processes under NSW is decidable while for RMO this problem is not decidable, which makes this memory models significant even if it does not describe any hardware implementation.
Further significant memory models include the `x86` (and `x86-64`) memory model formalized as `x86`-TSO, POWER and ARM memory models, and memory models of certain programming languages, namely Java Memory Models (Java was the first mainstream programming language with defined memory model), C11 and C++11.

## Sequential Consistency {#sec:sc}

Under sequential consistency all memory actions are immediately globally visible. That is, in the axiomatic description it holds that $\rel{ppo} = \rel{po}$ and $\rel{grf} = \rel{rf}$.
Furthermore, there are no fences as SC has no need for them.
In the operational semantics, this corresponds to machine without any caches and buffers where every write is immediately propagated to the global memory and every read reads directly from the memory.
This is the most intuitive and strongest memory model and it is often used by program analysers, but it is not used in most modern hardware.
This memory model corresponds to the interleaving semantics of parallel programs and therefore is the simplest to implement in analyzers of parallel programs.

## Total Store Order {#sec:tso}

Total store order (TSO) allows reordering of writes with following reads originating from the same thread that access different memory locations, i.e. it relaxes $w \rel{po} r$ pairs where $\loc{w} \neq \loc{r}$.
Also, the thread that invokes a read can read value from a program-order-preceding write even if this write is not globally visible yet (that is \rel{rfi} is not subset of \rel{grf}) \cite{TODO}.

Operational semantics can be described by a machine which has an unbounded, processor-local FIFO store buffer in each processor.
Writes are stored into the store buffer in the order in which they are executed.
If a read occurs, the processor first consults its local store buffer and it it contains an entry for the loaded address it reads newest such entry.
If there is no entry in the local store buffer, the value is read from the memory.]
An any point the oldest value from the store buffer can be removed from the buffer and stored to the memory.
This way the writes in the store buffer are visible only to the processor which issued them until they are (non-deterministically) flushed to the memory \cite{TODO}.

Machines which implement TSO-like memory models will usually provide memory barriers which flush the store buffer \cite{hw_view_for_sw_hackers, x86tso}.
A prominent example of TSO-like hardware are `x86` and `x86-64` processors.

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
This code demonstrates behavior which is allowed under TSO but is not allowed under SC. Suppose the following run of the program: first `x = 1` is executed, but the store is buffered and does not reach memory yet. Then `r1 = y` is executed, reading value 0 from `y`. Then the second thread is executed fully, and since the update of `x` was not yet propagated to the memory it reads 0 from `x`. Finally, the update of `x` (by action `a`) is performed.
\end{caption}
\label{fig:tso}
\end{figure}

## `x86`-TSO: `x86` and `x86-64` Processors

The memory model used by `x86` and `x86-64` processors is based on TSO with additional fences and atomic instructions.
The memory model is described informally in Intel and AMD specification documents \cite{TODO, TODO}.
Formal semantics derived from these documents and experimental evaluation was given in \cite{x86tso} in form of the `x86`-TSO memory model.
The semantics of `x86`-TSO is formalized in HOL4 model and as an abstract machine.
The abstract machine is rather simple, each processor core is connected to a local FIFO store buffer, to the memory, and to a memory lock (which is used for atomic instructions).
Writes write to the store buffer, reads read either from the newest entry in the store buffer (if such exists) or from the memory.

On top of stores and loads which behave as under the TSO memory model, `x86` has three fence instructions (`MFENCE`, `SFENCE`, and `LFENCE`).
Of these, `SFENCE` and `LFENCE` exist only for ordering of special instructions and are no-ops under `x86`-TSO.
`MFENCE` is a full memory barrier and it ensures that all writes performed on the same code before `MFENCE` are visible to the other processors (i.e. it flushes the local store buffer).
Furthermore, `x86` has a family of read-modify-write instructions (with the `LOCK` prefix, e.g. `LOCK XADD` for locked fetch-and-add) and a compare exchange instruction (`CMPXCHG`).
These instructions behave as if a memory lock was acquired before the operation, then the operation is performed, store buffers are flushed, and lock is released.

## Partial Store Order {#sec:pso}

Partial store order (PSO) is similar to TSO, but it also allows reordering of pairs of writes which do not access the same memory location ($w_1 \rel{po} w_2$ pairs).
Operational semantics corresponds to a machine which has separate FIFO store buffer for each memory location.
Again, processor can read from its local store buffers, but values saved in these buffers are invisible for other processors \cite{sparcmanual}.
PSO hardware will often include barriers both for restoration of TSO and SC \cite{TODO}.

An example for PSO-allowed run which is not TSO-allowed can be found in \autoref{fig:pso}.
This memory model is supported for example by SPARC in PSO mode, but this is not a common architecture and configuration \cite{sparcmanual, hw_view_for_sw_hackers}.
Therefore, this memory model is mostly important theoretically as reachability is decidable for it (see \autoref{sec:decidability}) and even incomplete analyses can be significantly simpler for PSO them for RMO or NSW.

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
This code demonstates behavior prohibited by TSO but allowed by PSO. In this case, the second thread waits for a guard `g` to be set and then attepts to read `x`. However, under PSO, writes to `x` and `g` can be reordered, resulting in action `d` reading from the initial value of `x`. Note that there is control flow dependency between `c` and `d`.
\end{caption}
\label{fig:pso}
\end{figure}

## Non-Speculative Writes {#sec:nsw}

The non-speculative writes memory model was introduced in \cite{Atig2012} as a memory model which is more relaxed then PSO, but its reachability problem for finite state processes is still decidable.
Operational semantics is also given in \cite{Atig2012}, but it is significantly more complicated then for PSO.
It allows also reordering of reads with other reads and it is defined with read-read and write-write fences and atomic read-modify-write instructions.
We show example of NSW behaviour which is not allowed by PSO in \autoref{fig:nsw}.
This memory model is proven to not allow causal cycles (which result in out-of-thin-air values).

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
An example for behaviour allowed by NSW but not allowed by PSO (or TSO).
While the two writes are well ordered, the corresponding reads are not and since the memory model relaxes read-read ordering they can observe values in different order.
The write fence is not necessary, if it would not be present the two threads would still not be able to observe different results under PSO, but it is used to demonstrate that read reordering more clearly.
\end{caption}
\label{fig:nsw}
\end{figure}

The operation model for this memory model is defined in \cite{Atig2012} using two-level store buffers and memory history buffer for reordering reads.

## Relaxed Memory Order {#sec:rmo}

The relaxed memory order (RMO) further relaxes PSO by allowing all pairs of memory operations to be reordering provided they don't access the same memory location.
That is, $\rel{ppo} = \rel{po-loc}$ except for cases when atomic instructions or fences are used.
Furthermore, as reads can be reordered, \rel{rfe} is not fully included in \rel{grf}.
A relaxation not allowed under PSO but allowed under RMO is demonstrated by the example in \autoref{fig:rmo}.

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
An example of behavior allowed by RMO, but not by TSO, PSO or NSW.
There are 4 threads, two of them writing one of `x` and `y`.
The remaining two threads read these variables, but observe their updates in inverted order (i.e. the third thread first reads new value of `x` and then old value of `y`, therefore it observes `x` first, but the last thread observes new value of `y` and then old value of `x`).
Please note that the read fences do not help in this case, as the two writes happen in independent threads an therefore are not ordered in any way with respect to each other (the are used only to distinguish from NSW).
\end{caption}
\label{fig:rmo}
\end{figure}

Operational semantics for RMO usually involve guessing loaded value at the point of the load instruction and validating it later.

Examples of hardware architectures with RMO-like memory models are POWER and ARM (and also Alpha, which has even more relaxed memory model but is not used much any more) \cite{hw_view_for_sw_hackers}.

- \cite{Atig2012} semantics for NSW with two level store buffers and history
  buffers for load reordering
- \cite{Alglave2013} - RMO??

## POWER Memory Model

## ARM Memory Model

# Memory Models of Programming Languages {#sec:langs}

Modern programming languages often acknowledge importance of parallelism and define memory behavior of concurrent programs. In general, most programming languages give guarantee that programs which correctly use locks for synchronization observe sequentially consistent behavior \TODO{tohle by chtělo nějak podložit}. On top of that, some programming languages, such as C, C++, and \TODO{?Java?} provide support for atomic operations which can be used for synchronization without locks in the platform they are running on supports it. C and C++ also support lower-level atomic operations with relaxed semantics which can be faster on platforms with relaxed memory.

## C and C++

In C and C++ prior to 2011 standards there was no support for threads and shared memory parallelism in the language.
Therefore creators of parallel programs were dependent on platform and compiler specific libraries and primitives, e.g. the `pthread` library for threading and `__sync_*` family of functions for atomic operations in the GCC compiler.

The C++11 and C11 standards introduced support for threading and atomic operations to these languages.
From the point of relaxed memory models, the interesting part of this is the support for atomic operations.
From now on, we will refer only to C++ and all examples will use C++ syntax, nevertheless, the C versions work the same (but the syntax can differ).

C++ provides atomic variables (using the templated class `std::atomic`{.cpp}, e.g. `std::atomic< int >`{.cpp}).
These variables can be used as normal variables, except that load from and stores to such variables are guaranteed to be sequentially consistent.
Furthermore, for integral types, operations such as increment and decrement are also guaranteed to be performed atomically.
Sequentially consistent atomic also guarantee that other memory actions will not be reordered across them and therefore they can be used for synchronization and guarding other (non-atomic) accesses.

As C++ is designed for high performance uses and not all parallel algorithms need sequential consistency, C++ has support for lower level atomic operations with more relaxed ordering.
These operations are executed by invoking appropriate member functions of the atomic object and can contain additional parameter which specifies their ordering.
Both sequentially consistent and lower-level atomics are shown in \autoref{fig:cppatomic}.

There are six memory orders in C++, namely *sequentially consistent*, *acquire-release*, *release*, *acquire*, *consume*, and *relaxed*. \TODO{…}.

C++ also has support for memory fences which take memory order argument too.
These memory fences can be used to strengthen synchronization guarantee among atomic operations (they are not required to give any guarantees if only non-atomic operations are used).

The C++ memory model is not formalized in C++11 standard, an attempt to formalize it was given in \cite{cppmemmod}, formalizing the N3092 draft of the standard \cite{N3092}.
While this formalization precedes the final C++11 standard, it seems[^cppmemmodvs11] that there were no changes in the specification of atomic operations after N3092.
Nevertheless, there are some differences between the formalization and N3092 (which are justified in the paper).

[^cppmemmodvs11]: \TODO{According to the clang compiler's C++ status page \cite{clangstatus} the documents defining semantics of C++ memory model and atomic instructions precede the N3092 draft.}

\begin{figure}[tp]

```{.cpp .numberLines}
std::atomic< int > x; // declaration an atomic variable
int y = 0; // non-atomic variable and store
x = 42; // sequentially consistent store
x.store( 16, std::memory_order_seq_cst );
x.store( 0, std::memory_order_relaxed );
y = 1;
x.store( 1, std::memory_order_release );
x += 4; // sequentially consistent
x.fetch_add( 4, std::memory_order_seq_cst );
```

\begin{caption}
Line 4 show explicit sequentially consistent store, line 5 show relaxed store. Line 6 contains non-atomic store which is ordered using release store on line 7. Lines 8 and 9 show two alternatives for executing the atomic fetch and add instruction.
\end{caption}
\label{fig:cppatomic}
\end{figure}

## Java

## LLVM

The LLVM memory model is derived from the C++11 memory model, with the difference that it lacks release-consume ordering and offers additional *Unordered* ordering which does not guarantee atomicity but makes results of data races defined (while in C/C++ data races on non-atomic locations yield the entire run of the program undefined) \cite{LangRef}.
The *Unordered* operations are intended to match semantics of Java memory model for shared variables \cite{LangRef}.

# Memory Models and Compilers {#sec:compilers}

When analysing programs in high level programming languages (as opposed to analysing assembly level programs), there can be substantially more relaxation then allowed by the memory model of the hardware these programs target.
The reason is that compilers are allowed to perform optimizations which reorder code or eliminate unnecessary memory accesses.
This is allowed as program order for programs in languages such as C++ is not a total order even if restricted to one thread.
For example, two loads of of non-atomic variables in C++ with the same memory location can be merged or load which follows a store to the same memory location can be assumed to yield the stored value and therefore can be eliminated.

These optimizations complicate analysis if they should be taken into account.
The two basic options for their handling include reasoning about all permitted reordering (see e.g. \cite{relaxed_opt_semantics_no_thin}), or side stepping the problem by using the same optimizing compiler to produce code both for verification and for actual execution (e.g. by verifying the binary or optimized intermediate representation of the compiler).
