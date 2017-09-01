---
vim: wrap linebreak nolist formatoptions-=t
---

Analysis and verification of parallel programs is undoubtedly desirable and memory models play an important role in the correctness of these programs; therefore, many techniques exist for analysis of parallel programs under various memory models.
In this chapter, we will first look into decidability of common verification problems under relaxed memory models and then we will review some of the approaches to the analysis.

These techniques can be split into two main areas.
The first area focuses on verification adherence of a program to a certain memory model if it runs under other, weaker (more relaxed), memory model.
For example, they can test whether a given program has no runs under TSO which would not be allowed under SC.
Some of these techniques also support fence insertion to restrict behaviours to that of the stronger memory model.

The second category aims at checking correctness of a program (according to some property) under a relaxed memory model (e.g. checking for assertion safety or memory safety or checking of LTL properties).
While the first category can be seen as a special case of the second, we consider the distinction notable as the techniques from the first category are usually not used to prove absence of certain types of erroneous behaviour, but assume that all relaxed behaviour is undesirable.

# Decidability and Complexity {#sec:decidability}

Right from the start it is important to note that even if we limit ourselves to programs with a finite number of finite-state threads/processes, there are important problems in widely-used memory models which are not decidable (while reachability under Sequential Consistency is in \PSPACE for such programs \cite{TODO}).

## Reachability of Error State

Here we ask if the program can reach an error (or goal) state from its initial state. 
In practice, there can be multiple error states which are given by some property which can be evaluated on each state separately, e.g. we can look for assertion violations or memory errors.

\medskip

According to \cite{wmdecidability}, the problem of state reachability in concurrent programs with finite-state processes running under relaxed memory models is decidable for TSO and PSO memory models, but not decidable for RMO (and therefore also not decidable for POWER and ARM).
The complexity of the state reachability in these programs under TSO and PSO is non-primitive recursive.
In \cite{Atig2012}, these decidability findings are further refined: a more relaxed decidable memory model, Non-Speculative Writes (NSW) is identified, and stronger claim about undecidability is proven, showing that adding relaxation that allows reordering reads after subsequent writes to TSO brings undecidability.

The proofs in \cite{wmdecidability} use a very simple program model with a finite number of finite-state control units and simple memory actions.
Furthermore, they assume that the number of memory locations and processes is fixed and that the data domain is finite.
On the other hand, in practice both valid memory locations and processes can be created during the run of the program (and even though there is an upper bound on their number, this upper bound is not practical for the use in analysis).

## Verification of Liveness Properties

Liveness properties described by Linear Temporal Logic (LTL) or Computational Tree Logic (CTL) are important class of properties often considered especially in connection with reactive systems and explicit-state model checking \cite[Chapter 3]{Clarke1999}.
They allow users to specify properties such as reaction to a certain event or repeated occurrence of an event and they are evaluated on infinite runs of the program.
With the automata-based approach to explicit-state model checking these problems are solved by solving repeated reachability of accepting states of \buchi product automaton derived from the program and the specification \cite[\S 5.2]{Baier2008}.

\medskip

According to \cite{wmdecidability}, repeated reachability, which can be used as a basis for verification of LTL properties, is not decidable even for TSO.
Furthermore, from the construction of the reduction in the repeated reachability undecidability proof and from \cite{abdulla1996undecidable} it follows that both LTL and CTL model checking problems are undecidable for TSO.
Therefore LTL model checking is undecidable for all memory models more relaxed than SC shown in this work.
For SC, it is well known that LTL model checking is in \PSPACE for finite-state programs \cite{Sistla1985}.

## Verification of Absence of SC Violations

Here the question is whether a program, when run under a relaxed memory model, exhibits any runs not possible under SC.
This problem is explored under many names, e.g. (TSO-)safety \cite{Burckhardt2008}, robustness \cite{Bouajjani2013, Derevenetc2014}, and stability \cite{Alglave2011}.

\medskip

Interestingly, \cite{Derevenetc2014} shows that even for the POWER memory model, checking robustness of programs with a finite number of finite-state threads is in \PSPACE, using an algorithm based on reduction to language emptiness.
For PSO and TSO, \PSPACE algorithm for robustness is shown by \cite{Burnim2011}, this time the algorithm is based on monitoring of SC runs of the program.
This shows that checking that a program does not exhibit relaxed behaviour is significantly simpler than checking if this behaviour can actually lead to an error.

## Consequences of Decidability and Complexity Results

It can be seen that analysis of a program under a relaxed memory model is a hard task, much harder than for a program running under SC.
For this reason most analysis techniques cannot be used to prove the absence of errors, or only in cases when the program is robust to the given memory model.
In practice most analysis tools use some kind of constraining of the memory-model-induced reordering: for example bounding the number of instructions which can be reordered, or bounding the number of context switches.

# Robustness Checking {#sec:analysis:adherence}

As shown in the previous section, checking robustness (the absence of relaxed behaviour) is significantly less complex than verifying absence of errors in relaxed runs.
For this reason, there is an interest in combination of verification under sequential consistency with a robustness checker \cite{Burckhardt2008}.
This way, it is possible to check that program is correct under SC and whether all relaxed runs are equivalent to some SC runs.
If both of these checks succeed, it can be concluded that the program is correct under a given relaxed memory model.
However, the disadvantage of this technique is that for correctness analysis of parallel programs it can vastly over-approximate possible errors.
In practice it is often desirable to allow relaxed behaviours, provided they do not lead to errors: a careful use of relaxed memory can yield much better performance than restricting the program to SC \cite{TODO?}.

\bigskip

In \cite{Burckhardt2008}, the SOBER tool, which allows detection of TSO violations, is presented.
This tool works by monitoring sequentially consistent runs of the program and detecting violations which would occur under TSO.
The monitoring algorithm is based on vector clocks and axiomatic definition of TSO.

An alternative approach to checking robustness by monitoring SC runs is presented in \cite{Burnim2011}.
This approach allows checking robustness under both TSO and PSO and is built on the operational semantics of these memory models.
This monitoring algorithm is implemented in the tool THRILLE and should be asymptotically faster than the one presented in \cite{Burckhardt2008} while also being sound and complete.

Another possibility for checking TSO robustness is to use *attacks*, a form of restricted out-of-order execution which witnesses SC violations.
This approach is presented in \cite{Bouajjani2013}, together with an implementation in the \textsc{Trencher} tool which uses the SC model checker Spin \cite{Holzmann1997} as the backend for validation of attacks.

Restring programs running under the `x86` or POWER memory models to SC behaviours is explored in \cite{Alglave2011}.
The work also presents \textsf{offence}, a tool which inserts synchronization into `x86` or POWER assembly to ensure stability.

Concerning stronger memory models, \cite{Derevenetc2014} shows an algorithm for checking robustness under POWER, but does not provide any implementation.
The algorithm presented in this work also assumes that the number of processes is fixed and each process is a finite automaton, therefore it is not directly applicable to robustness checking of real-world programs.

For programming languages with the data race free guarantee,[^drf] data race freedom can be used as sufficient condition for robustness.
The problem of data race detection is explored for example in \cite{Yang2004} for the Java Memory Model (JMM).
In this case we ask if the program uses enough synchronization to avoid any data races.
However, as the JMM defines data races in terms of SC executions, this work only formalizes SC.
The entire program, memory constraints, and the specification is encoded as a constraint solving problem, which can be solved by a constraint solver, e.g. Prolog with finite domain data.
This work is accompanied by the  *DefectFinder* tool.

[^drf]: Stating that data race free programs observe only sequentially consistent behaviours.

# Direct Analysis Techniques

Many techniques for safety analysis of programs under relaxed memory models fall into the category of bug finding tools -- such tools are unable to prove correctness in general, but they provide substantially better coverage of possible behaviours of parallel program than testing.
This incompleteness is mostly caused by either bound on the number of instructions which can be reordered or number of context switches the program can do during any explored run.

There are several reasons for this bounding; the obvious one is the time complexity of the analysis, but another important reason is that dealing with programs in programming languages is substantially more difficult than dealing with programs represented as a composition of finite-state processes (as assumed in the complexity analyses).

### Transformation-Based Techniques

A widely used family of methods for analysis of relaxed memory models is based on transformation of an input program $P$ into a different program $P'$ such that running $P'$ under sequential consistency allows us to explore runs equivalent to running $P$ under a more relaxed memory model.
The main advantage of this approach is that it makes it possible to reuse existing analysis tools for sequentially consistent programs together with all the advancements in their development.
In most cases the transformation also includes some way of bounding relaxation and therefore this allows exploring only a subset of runs of $P$.
Further under-approximation might be caused by the used SC analyser (e.g. when bounded model checker is used as a backend).

In \cite{Alglave2013} a transformation-based technique for the `x86`, POWER, and ARM memory models is presented.
This transformation is parametrized and can be tweaked to implement different memory models.
It is implemented in the `goto-instrument` tool for instrumentation of `goto`-programs.
As `goto`-programs can be created by translation from C, this work primarily focuses on C programs.
The output of the transformation is a `goto`-program which can be verified directly by some analysers, or translated back to C.
The technique presented in this work is sound, but not complete (due to buffer bounding and possible incompleteness in the backend).
It is also not clear if it can cover all cases of delaying reads after writes.
The work is accompanied by Coq proofs matching the axiomatic semantics to the operational semantics used for the implementation.
\comment{sound but not complete (buffer bounding, loop bounding (if using BMC),
    probably not full RMO), general both in memory model and in tools used as
    backend, Coq proof that operational semantics matches
    \cite{Alglave2010_fences}. C/goto-programs.}

Another approach to program transformation is taken in \cite{Atig2011}, in this case the transformation uses context switch bounding but not buffer bounding and it uses additional copies for shared variables for TSO simulation.
Two options for the transformation are presented, in the first one the total number of context switches is limited, in the second there is a limited number of context switches the value can be delayed for, but the overall analysis is not context-switch-bounded.
There is no tool accompanying this publication -- the experiments were performed using manually translated C programs.

In \cite{Abdulla2017} the context-bounded analysis using transformation is applied to the POWER memory model.
The resulting program uses nondeterminism heavily to guess the results of a sequence of instructions which is later checked.
It uses bounded model checker CBMC as a backend.
The publication is accompanied by the `power2sc` tool which implements the transformation of C programs.
\comment{-- Context bounded analysis for the POWER architecture, by transformation of program.
    Uses nondeterminism heavily to guess result of sequence of instructions which is later checked.
    CBMC is used as a backend.
    It shows that context bounded analysis for POWER is decidable. 
    Tool `power2sc`, compared with goto-instrument and niddhug.
    Evaluation on C programs.
    In a way extension of \cite{Atig2011}.}

Our own work in \cite{SRB15weakmem} presents a transformation of LLVM bitcode to simulate buffer-bounded TSO runs.
It targets DIVINE and therefore C and C++ programs.

### Stateless Model Checking

Stateless Model Checking methods are intended for safety analysis of terminating programs in real-world programming languages \cite{Godefroid1997}.
They employ Dynamic Partial Order Reduction (DPOR) to avoid exploring equivalent runs of the program \cite{Flanagan2005dpor} and the works concerning relaxed memory models in this setting often discuss interlay between DPOR and relaxed memory model in length.

A stateless model checking approach to the analysis of programs running under the C++11 memory model (with the exception of release-consume synchronization) is presented in \cite{Norris2013}.
It uses custom implementation of C++ thread and atomic libraries to produce binaries which perform the analysis.
It lazily builds relations between memory operations in the form of a *modification order graph*. 
This representation prevents exploration of infeasible executions as well as unnecessary distinction between equivalent executions.
Furthermore, as the C++ memory model allows reordering of reads with future operations, the authors propose to simulate this by propagating stored values to previous loads and validating this speculation (which does not simulate out-of-thin-air values).
The paper includes a long discussion on features of the C++ memory model and the corresponding implementation in \textsc{CDSChecker}, which is usable for (small) unit tests of concurrent data structures written in C11 or C++11.

In \cite{Zhang2015} the authors focus mostly on modelling of TSO and PSO and its interplay with DPOR.
They combine modelling of thread scheduling nondeterminism and memory model nondeterminism using store buffers to a common framework.
This is done by adding store buffers to the program and adding shadow thread for each store buffer which is responsible for flushing contents of this buffer to the memory.
The proposed approach is implemented in the tool *rInspect*, which is an LLVM-based stateless model checker which supports both unbounded store buffers and buffer bounding (however, as it is a stateless model checker, it works only on programs which terminate).

Another approach to combining TSO and PSO analysis with stateless model checking is presented in \cite{Abdulla2015}.
In this work executions are represented by chronological traces which capture dependencies required to represent interaction between memory actions.
These chronological traces are acyclic relations and therefore can be used for DPOR, including the optimal DPOR which explores exactly one execution in the equivalence class of the partial order \cite{Abdulla2014}.
The advantage of this approach is that for robust programs, using the optimal DPOR algorithm with chronological traces should produce the same number of executions under SC as under relaxed memory model.
The proposed approach is implemented in an LLVM-based tool Niddhugg, which supports analysis of C programs with pthreads parallelism and with a bounded execution length.

### Unbounded Methods

There are also analysis methods which aim to be able to discover any memory-model-related bugs, regardless of number of instructions being reordered or number of context switches.

An approach to verification of programs under TSO, which uses unbouded store buffers, is presented in \cite{Linden2010}.
It uses store buffers represented by automata and leverages cycle iteration acceleration (for cycles involving changes in only one store buffer) to get representation of store buffers on paths which would form cycles if values in store buffers were disregarded.
It uses sleep set POR to reduce state space.
The provided tool targets a modified Promela language \cite{Holzmann1997}.
Since the cycle acceleration is limited to changes in one store buffer, it is not clear if the algorithm is guaranteed to terminate.

Another unbounded approach is presented in \cite{Bouajjani2015} -- it introduces TSO behaviours lazily by iterative refinement, and while it is not complete, it should eventually find all errors.
This work is based on the robustness checker presented in \cite{Bouajjani2013} and uses it to detect runs to which relaxed behaviour should be added.
The work is accompanied by an implementation in the tool \textsc{Trencher}.

### Other Methods

In \cite{Park1995}, the SPARC hierarchy of memory models (TSO, PSO, RMO) is modelled using encoding from assembly to Mur$\varphi$ \cite{Murphi}.
The encoding allows all reordering of instructions allowed by a given memory model up to a certain reordering bound.
This work targets small synchronization primitives such as spin locks.

In \cite{Huynh2006} an explicit state model checker for C# programs (supporting subset of C#/.NET bytecode) which uses the .NET memory model is presented.
The verifier first verifies program under SC and then it explores additional runs allowed under the .NET memory model.
It can also insert barriers into the program to avoid relaxed runs which violate a given property.
The implementation of the exploration algorithm uses a list of delayed instructions to implement instruction reordering.
While the authors mention that the number of reordered instructions is not bounded, they do not discuss how this approach works for programs with cycles.

The work \cite{Dan2013} presents an approach for verification of (potentially infinite state space) programs under TSO and PSO using predicate abstraction.
The paper first shows that it is not possible to use traditional predicate abstraction to produce a boolean program and then verify this boolean program using weak memory semantics.
Instead, they propose a schema which first verifies the program under SC and then extrapolates predicates from the SC run to verify a transformed version of the original program which has store buffers explicitly encoded.
The store buffers are bounded in this transformation.
Implementation in the tool \textsc{cupex} is also provided.

A completely different approach is taken in \cite{Turon2014}.
This work introduces a separation logic GPS, which allows proving properties about programs using (a fragment of) the C11 memory model.
That is, this work is intended for manual proving of properties of parallel programs, not for automatic verification.
The memory model is not complete, it lacks relaxed and consume-release accesses.
Another fragment of the C11 memory model is targeted by the RSL separation logic introduced in \cite{Vafeiadis2013}.
