---
vim: wrap linebreak nolist formatoptions-=t
---

The behavior of a program in presence of relaxed memory is described by relaxed memory model. The relevant memory model depends on the programming language of choice (as it can allow reordering of certain actions for the purpose of optimizations) and on the hardware on which the program is running. It also depends on the compiler (or interpreter or virtual machine, depending on the programming language of choice) which is responsible for translating the program in a way that it meets the guarantees given in the specification of the programming language. We will, however, abstract from the impact of the compiler and expect it to be correct in most cases. We will also abstract from the impact of an operating system's scheduler which can move program threads between physical processing units, which could be visible in memory behavior, but the operating system should make sure this effect is not visible.

When dealing with the memory model of the hardware, it is usually neither possible nor useful to discuss the behavior of the concrete CPU, instead, we discuss the behavior of a certain platform (e.g. Intel `x86` or POWER). There are at least two good reasons for this: first, results which take into account only the concrete CPU might not be applicable to any other CPU, even from the same family, and second, the exact architecture is usually kept secret by the company manufacturing those CPUs. Sadly, the second problem also partially applies to descriptions of the behavior of CPU platforms: relaxed memory behavior is usually described by informal documents and not by a formal specification and therefore is open to misinterpretation. Some of such problems can be found for example in the description of the `x86` memory model (x86-TSO) \cite{x86-TSO}. Furthermore, even when we have a formal description of the behavior of a certain platform, this description usually over-approximates possible behaviors of the program. For example, no reasonable platform can delay an arbitrary number of memory writes, but the x86-TSO memory model allows it as the bound on such reordering is unknown.

Alternatively, one might describe a memory model of a programming language (or compiler, if the programming language in question does not define memory behavior of parallel programs). This would then allow analysis of the program to reason about its behavior on any platform for which it can be compiled (provided the compiler is correct). The disadvantage is that, similar to CPU platforms, programming languages usually lack a precise formal description of the memory model, see e.g. \cite{cppmemmod} for analysis of (\TODO{draft of}) C++11 standard. Furthermore, such specifications can often be unnecessarily strict: for example, according to C++11, any parallel programs in which two threads communicate without presence of locks or atomic operations has an undefined behavior and therefore can have arbitrary outcome, but in practice communication using volatile variables (and possibly compiler specific memory fences) can work well with most compilers and is often used in legacy code written before C++11 (or C11 in the case of C).

In the following sections, we will first look into hardware constructs which give rise relaxed memory (\autoref{sec:hw}), then, in \autoref{sec:semantics} we will introduce two possibilities of precise characterization of memory models, namely an axiomatic approach based on relations between memory actions of the program and an operational model. In \autoref{sec:models} we will then describe common theoretical memory models and in \autoref{sec:hwmodels} we will relate them to particular architectures. Finally, in \autoref{sec:langs} we will describe memory models of C++ and Java programming languages and of the LLVM intermediate language and in \autoref{sec:compilers} we will discuss the impact of compiler optimizations on memory models.

#### Memory Models Concerning a Program

*   memory model of the actual hardware the program runs on
*   theoretical memory models abstracting hardware memory models
*   memory model of the programming language (if any)
*   memory model in the mind of the programmer

# Hardware View of Memory Relaxation {#sec:hw}


In order to understand certain characteristics of relaxed memory models, it is useful to know what hardware constructs give rise to memory relaxation and why they are used.

As the memory is significantly slower that the CPU, the CPU contains cache memories which can store part of the information in the main memory in the way which makes the access faster \cite{TODO}. In modern CPUs, there are usually multiple levels of cache memory, often two or three, some of which are local to a CPU core and some might be shared among several cores of the CPU \cite{TODO}. If multiple threads work with the same memory it is important they have a consistent view of the memory, even if the values are cached in different caches. To achieve this cache consistency, CPUs employ cache coherence protocols and memory relaxations arise from optimizations of these protocols \cite{hw-view-for-sw-hackers}.

\TODO{…}

\TODO{atomic instructions}

# Description of Memory Model Semantics {#sec:semantics}

As already noted, it is often the case that CPU architecture specifications or language specifications describe memory models in an informal way. This, however, can lead to imprecision when such specification is used for as a basis for a program, compiler or analyzer implementation. For this reason, it is useful to have formal semantics given to memory models.

Two main options are used for the description of memory model semantics, an axiomatic semantics based on dependency relations between actions of the program \cite{TODO, TODO}, and operational semantics which describes working of an abstract machine which implements the given memory model \cite{TODO, TODO}.

## Axiomatic Semantics

The axiomatic semantics of memory models builds on relations between various (memory related) actions of the program and properties of these relations. We will mostly use the framework presented in \cite{alglave-fences} which classifies several dependency relations (some of which are memory model dependent) and for each memory model, a union of some of these relations needs to be acyclic.

Following \cite{alglave-fences} we now introduce relations between memory operations. All these relations are partial orders. We will denote reads by $r$ ($r_1, r_2, …$), writes by $w$ ($w_1, w_2, …$), and arbitrary memory operations by $m$ ($m_1, m_2…$). A read or write can also be part of atomic read-modify-write operation.

Program order
~   $m_1 \rel{po} m_2$, is a total order of actions performed by one processor (or thread). It never relates actions from different threads. Some instructions might consist of multiple memory accesses which are ordered according to their intra-instruction dependencies (e.g. the `lock xadd` `x86` instruction performs first a read and then a write that are ordered by \rel{po} \cite{x86tso}).

Dependencies
~   $r \rel{dp} m$, represents data and control dependencies between instructions, it is a subrelation of \rel{po} and its source is always a read.

Location program order
~   $m_1 \rel{po-loc} m_2$, is a restriction of \rel{po} in which $m_1$ and $m_2$ has to access the same memory location.

Preserved program order
~   $m_1 \rel{ppo} m_2$, is a subrelation of \rel{po} which is preserved by the given memory model (e.g. \tso does not preserve $w \rel{po} r$ pairs for different memory locations, \pso also does not preserve $w \rel{po} w$ pairs \cite{sparcmanual}).

Read-from map
~   $w \rel{rf} r$, links a write to a read which reads its value. For each read $r$ there is a unique write $w$ such that $w \rel{rf} r$.

External read-from map
~   $w \rel{rfe} r$, is a subrelation of \rel{rf} which links only events from distinct threads.

Internal read-from map
~   $w \rel{rfi} r$, is a subrelation or \rel{rf} which links only events the same thread.

Global read-from
~   $w \rel{grf} r$, is a subrelation of \rel{rf} which is preserved by a given memory model.

Write serialization
~   $w_1 \rel{ws} w_2$, is a total order on writes to the same memory location (i.e. the order in which writes become visible to all threads). \TODO{Often also denoted as ?coherence order?}

From-read map
~   $r \rel{fr} w$, denotes that $r$ reads from a write which precedes $w$ immediately in \rel{ws}. \TODO{Often also denoted as ?conflict relation?} It can be defined as $r \rel{fr} w \stackrel{def}{=} \exists w'. w' \rel{rf} r \land w' \rel{ws} w$.

Barrier ordering
~   $m_1 \rel{ab} m_2$, is ordering introduced by memory barriers (fences). It depends on the fence instructions of the platform and therefore on the memory model.

Global happens-before
~   $m_1 \rel{ghb} m_2$, is a union of relations which are global. \rel{ws} and \rel{fr} are always included in \rel{ghb}. \rel{ppo}, \rel{grf}, and \rel{ab} are also included, but their definition depends on the memory model. That is, $\rel{ghb} \stackrel{def}{=} \rel{ppo} \cup \rel{ws} \cup \rel{fr} \cup \rel{grf} \cup \rel{ab}$.

In this framework, the memory model is given by the choice of these relations. In all cases, there are three constraints which must be met.

\rel{ghb} must be acyclic
~   this corresponds to the fact that it (partially) orders actions of the program.

Memory coherence of each location must be respected
~   i.e. $\rel{po-loc} \cup \rel{rf} \cup \rel{ws} \cup \rel{fr}$ must be acyclic.

No *out of thin air* values
~   i.e. $\rel{rf} \cup \rel{dp}$ must be acyclic. \TODO{This means that …}, \TODO{some theoretical memory models do not follow this}


This classification now allows us to decide the validity of an execution under a given memory model: we must classify ordering between actions of this execution and check that these relations follow the three constraints mentioned above.

## Operational Semantics


# Theorectical Memory Models {#sec:models}

## Sequential Consistency {#sec:sc}

## Total Store Order {#sec:tso}

## Partial Store Order {#sec:pso}

## Relaxed Memory Model {#sec:rmo}

# Memory Models of Hardware Architectures {#sec:hwmodels}

## AMD64

## ARM

## Power

# Memory Models of Programming Languages {#sec:langs}

## C and C++

## Java

## \llvm

# Memory Models and Compilers {#sec:compilers}

## Adherence to Language Memory Models

## Optimizations

