---
vim: wrap linebreak nolist formatoptions-=t
---

As analysis and verification of parallel programs is desirable and memory models play important role in correctness of these programs, there are many techniques for analysis of parallel programs under various memory models.
In this chapter, we will first look into decidability of common verification problems under relaxed memory models and then we will review some of the analysis techniques.

Such techniques can be split into two main areas, first area contains techniques which verify adherence of program to certain memory model if it runs under other, weaker (more relaxed), memory model.
For example, they can test that given program has no TSO-enabled runs which would not be allowed under SC.
Some of these techniques also support fence insertion to restrict behaviours to that of the stronger memory model.

The second category contains techniques which check correctness of program (according to some property) under relaxed memory model (e.g. checking for assertion safety or memory safety, or checking for LTL properties).
While the first category can be seen as a special case of the second, we consider the distinction important as the techniques from the first category are usually not used to prove absence of certain types of erroneous behavior, but assume that all relaxed behavior is undesirable.
Furthermore, in the second category, we consider both precise and approximative techniques.

# Decidability and Complexity {#sec:decidability}

Right from the start it is important to note that even if we limit ourselves to programs with finite-state processes there are important problems in important memory models which are not decidable (while reachability under Sequential Consistency is in \PSPACE for such programs).

## Reachability of Error State

In this problem we ask if the program can reach an error (or goal) state from its initial state. 
In practice, there can be multiple error states which are given by some property which can be evaluated on each state separately, e.g. we can look for assertion violation or memory errors. 

According to \cite{wmdecidability} the problem of state reachability in concurrent programs with finite-state processes under relaxed memory models is decidable for TSO and PSO memory models, but not decidable for RMO (and therefore also not decidable for POWER and ARM).
The complexity of the state reachability in these programs under TSO and PSO is non-primitive recursive.
In \cite{Atig2012}, these decidability finding are further refined: a more relaxed decidable memory model, Non-Speculative Writes (NSW) is identified, and stronger claim about undecidability is proven, showing that adding relaxation which allows reordering reads after subsequent writes to TSO brings undecidability.

The proofs in \cite{wmdecidability} use a very simple program model with finite-state control unit and simple memory actions.
Furthermore, they assume that the number of memory locations and processes is fixed and that the data domain is finite.
On the other hand, in practice both valid memory locations and processes can be created during the run of the program (and even though there is an upper bound of their number, this upper bound is not practical for use in analysis).

## Verification of Linear-Time Properties

An important class of properties are properties described by Linear Temporal Logic (LTL), \cite{TODO}.
These properties are often considered especially in connection with reactive systems and explicit-state model checking \cite{TODO}. 
They allow users to specify properties such as reaction to certain event or repeated occurrence of an event and they are evaluated on infinite runs of the program.
With the automata-based approach to explicit-state model checking these problems are solved by solving repeated reachability of accepting states of \buchi product automaton derived from the program and the specification \cite{TODO}.

According to \cite{wmdecidability}, repeated reachability, which can be used as basis for verification of LTL properties, is not decidable even for TSO.
Furthermore, from the construction of the reduction in the repeated reachability undecidability proof and from \cite{abdulla1996undecidable} it follows that LTL  and CTL model checking problem for TSO is also undecidable.
Therefore LTL model checking is undecidable for all memory models more relaxed then SC shown in this work.
For SC, it is well known that LTL model checking is in \PSPACE for finite-state programs \cite{TODO}.

## Verification of Absence of SC Violations

In this problem we ask if the program, when run under a relaxed memory model, does exhibit any runs not possible under SC.
This problem is explored under many names, e.g. \cite{Burckhardt2008} uses notion of TSO-safety, \cite{Bouajjani2013} and \cite{Derevenetc2014} use notion of robustness, and \cite{Alglave2011} uses notion of stability (which is slightly more general as it can relate two relaxed memory models together).

Interestingly, \cite{Derevenetc2014} shows that even for the POWER memory model, checking robustness of programs with finite number of finite-state threads is in \PSPACE, using an algorithm based on reduction to language emptiness.
For PSO and TSO, \PSPACE algorithm for robustness is shown by \cite{Burnim2011}, this time the algorithm is based on monitoring of SC runs of the program.
This shows that checking that program does not exhibit relaxed behavior is significantly simpler than checking if this behavior can actually lead to an error.

## Verification of Compliance of Hardware to a Memory Model

There is also some work on verifying whether a hardware implements a given memory model.
As this problem is not directly related to software verification, we will not consider such problems.

# Verification of Absence of SC Violations {#sec:analysis:adherence}

As the reachability problem for programs under relaxed memory models is either very expensive to solve or undecidable, an alternative approach was proposed which builds on combination of analysis under sequential consistency with a procedure which verifies that no runs under the given relaxed memory model expose behavior not exposed under SC \cite{Burckhardt2008}.
he advantage of this combination is that, at least for some memory models, it has significantly lower complexity than the error reachability problem.
For example, in the case of finite-state processes, the TSO robustness problem is in \PSPACE, the same complexity class as the SC reachability problem.
Therefore, robustness based verification of finite-state processes under TSO is in \PSPACE while TSO error reachability is non-primitive recursive.

However, the disadvantage of these techniques is that for correctness analysis of parallel programs they can vastly over-approximate possible errors as in practice it is often desirable to allow relaxed behaviors, provided it does not lead to an error, as it can yield much better performance.

The works \cite{Burckhardt2008, Burnim2011} build on detecting TSO (in the case of \cite{Burckhardt2008}, tool SOBER) or both TSO and PSO (\cite{Burnim2011}, tool THRILLE) violations by monitoring sequentially consistent executions of programs.
A more general notion of stability (which relates two arbitrary memory models) is used in \cite{Alglave2011} which explores recovering of SC from `x86` or POWER memory model.
The work also presents the tool \textsf{offence} which inserts synchronization into `x86` or POWER assembly to ensure stability.
Another approach for detecting non-SC behaviour (under TSO) is presented in \cite{Bouajjani2013}.
This approach uses a notion of *attacks*, a form of restricted out-of-order execution which witnesses SC violation.
Authors also provide an implementation in the tool \textsc{Trencher} which uses SC model checker (Spin \cite{Holzmann1997}) as a backend for validation of attacks.

*   \cite{Yang2004} -- Presents formal semantics for a simple programming language including its precise memory semantics.
    The motivation is to provide verification procedure for detecting data races under the Java Memory Model (JMM).
    The formalization uses SC as it is sufficient for detection of data races under JMM (JMM defines data race freedom in terms on SC runs).
    The entire program, memory constraits, and specification is encoded as constraint solving problem, which can be solved by constraint solver, e.g. Prolog with finite domain data as used in the presented tool
    *DefectFindrer*.

*   \TODO{Nemos framework (Non-operational yet Executable Memory Ordering Specification) -- Nemos: A framework for axiomatc and executable specificfication of memory consistency models.}

*   \cite{Burnim2011} -- Present algorithms for finding violations of SC under TSO or PSO.
    The algorithm explores only SC runs while keeping additional information for violation detection.
    The algorithm is based on operational semantics for TSO and PSO and should be asymptotically faster then the one presented in \cite{Burckhardt2008} while also being sound and complete.
    There is also implementation in the tool THRILLE.

# Direct Analysis Techniques

There are many techniques for analysis of programs under relaxed memory models which mostly fall into the category of bug finding tools -- such tools are unable to prove correctness in general, but they provide substantially better coverage of possible behaviors of parallel program then testing.
Mostly, this incompleteness is caused by either bound on the number of instructions which can be reordered or number of context switches the program can do during any explored run.

There are several reasons for this bounding, the obvious one is the time complexity of the analysis, but another important reason is that dealing with programs in programming languages is substantially more difficult then dealing with programs given as composition of finite-state processes (as assumed in the complexity analyses).

### Transformation-Based Techniques

A widely used family of methods for analysis of relaxed memory models is based on transformation of an input program $P$ into a different program $P'$ such that running $P'$ under sequential consistency allows us to explore runs equivalent to running $P$ under some more relaxed memory model.
The main advantage of this approach is that it makes it possible to reuse existing analysis tools for sequentially consistent programs together with all the advancements in their development.
In most cases the transformation also includes some way of bounding relaxation and therefore this allows us exploring only a subset of runs of $P$ and further under-approximation might be caused by the used SC analyser (e.g. if bounded model checker is used as a backend).

In \cite{Alglave2013} a transformation-based technique for the `x86`, POWER, and ARM memory models is presented.
The transformation parametrized and can be tweaked to implement different memory models.
The transformation is implemented in the tool `goto-instrument` for instrumentation of `goto`-programs which can be created by translation from C and therefore it primarily focuses on C programs.
The output of the transformation is a `goto` which can be verified directly by some analysers, or translated to C.
The technique presented in this work is sound, but not complete (due to buffer bounding and possible incompleteness in the backend).
It is also not clear if it can cover all cases of delaying reads.
The works is accompanied by Coq proofs matching the axiomatic semantics to the operational used for the implementation.
\comment{sound but not complete (buffer bounding, loop bounding (if using BMC),
    probably not full RMO), general both in memory model and in tools used as
    backend, Coq proof that operational semantics matches
    \cite{Alglave2010_fences}. C/goto-programs.}

Another approach to program transformation is taken in \cite{Atig2011}, it this case the transformation uses context switch bounding but not buffer bounding and it uses additional copies for shared variables for this simulation.
The memory model used is TSO and two options for the transformation are presented, in the first one the total number of context switches is limited, in the second there is a limited number of context switches the value can be delayed for, but the overall analysis is not context-switch-bounded.
There is no tool accompanying this publication -- the experiments were performed using manually translated C programs.

In \cite{Abdulla2017} the context-bounded analysis using transformation is applied to the POWER memory model.
The resulting program uses nondeteterminism heavily to guess results of sequence of instructions which is later checked.
It uses bounded model checker CBMC as a backend.
The publication is accompanied by a tool `power2sc` which implements the transformation of C programs.
\comment{-- Context bounded analysis for the POWER architecture, by transformation of program.
    Uses nondeterminism heavily to guess result of sequence of instructions which is later checked.
    CBMC is used as a backend.
    It shows that context bounded analysis for POWER is decidable. 
    Tool `power2sc`, compared with goto-instrument and niddhug.
    Evaluation on C programs.
    In a way extension of \cite{Atig2011}.}

Our own work in \cite{SRB15weakmem} presents transformation of LLVM bitcode to simulate buffer-bounded TSO runs.
It targets DIVINE and therefore C and C++ programs.

### Stateless Model Checking

Stateless Model Checking methods are intended for safety analysis of terminating programs in real-world programming languages \cite{Godefroid1997}.
They employ Dynamic Partial Order Reduction (DPOR) to avoid exploring equivalent runs of the program \cite{Flanagan2005dpor} and the works regarding relaxed memory models in this setting often discuss interlay between DPOR and relaxed memory model in length.

The work \cite{Norris2013} presents a stateless model checking approach to the C++11 memory model (with the exception of release-consume synchronization).
It uses custom implementation of the C++ thread and atomic libraries to produce binaries which performs the analysis.
It lazily builds relations between memory operations in the form of the *modification order graph*, which prevents exploration of infeasible executions as well as unnecessary distinction between equivalent executions.
Furthermore, as the C++ memory model allows reordering of reads with future operation, the proposed technique allows this by propagating stored values to previous loads and validating this speculation.
The paper includes a long discussion about features of the C++ memory model and the corresponding implementation in \textsc{CDSChecker}, which is usable for (small) unit tests of concurrent data structures written in C11 or C++11.

In \cite{Zhang2015} authors focus mostly on modelling of TSO and PSO and its interplay with DPOR.
They combine modelling of thread scheduling nondeterminism and memory model nondeterminism using store buffers to a common framework.
This is done by adding store buffers to the program and adding shadow thread for each store buffer which is responsible for flushing contents of this buffer to the memory.
The proposed approach is implemented in tool *rInspect*, which is a LLVM-based stateless model checker and it supports both unbounded store buffers and buffer bounding (however, as it is a stateless model checker, it works only on programs which terminate).

Another approach to combining TSO and PSO analysis with stateless model checking is presented in \cite{Abdulla2015}.
In this work executions are represented by chronological traces which capture dependencies required to represent interaction between memory actions.
These chronological traces are acyclic relations and therefore can be used for DPOR, including the optimal DPOR which explores exactly one execution in the equivalence class of the partial order \cite{Abdulla2014}.
The advantage of this approach is that for robust programs, using the optimal DPOR algorithm with chronological traces should produce the same number of executions under SC as under relaxed memory model.
The proposed approach is implemented in LLVM-based tool Niddhugg which supports analysis of C programs with pthreads parallelism and with bounded execution length.

### Unbounded Methods

There are also analysis methods which aim at being able to discover any memory-model-related bugs, regardless on number of instructions being reordered or number of context switches.

The work \cite{Linden2010} presents approach to verification of programs under TSO with unbouded store buffers.
It uses store buffers represented by automata and leverages cycle iteration acceleration (for cycles involving changes in only one SB) to get representation of store buffers on paths which would form cycles if values in store buffers were disregarded.
It uses sleep set POR to reduce state space.
The provided tool targets modified Promela language \cite{Holzmann1997}.
Due to the limitation of acceleration to changes only in one store buffer it is not clear if the algorithm is guaranteed to terminate.

Another unbounded approach is presented in \cite{Bouajjani2015} -- it introduces TSO behaviors lazily by iterative refinement, and while it is not complete it should eventually find all errors.
This work is based on the robustness checker presented in \cite{Bouajjani2013} and uses it to detect runs to which relaxed behavior should be added.
There is also implementation in the tool \textsc{Trencher}.

### Other Methods

In \cite{Park1995}, the SPARC hierarchy of memory models (TSO, PSO, RMO) is modelled using encoding from assembly to Mur$\varphi$ \cite{murphi}.
The encoding allows all reordering of instructions allowed by given memory model to a certain reordering bound.
This work targets small synchronization primitives such as spin locks.

In \cite{Huynh2006} an explicit state model checker for C# programs (supporting subset of C#/.NET bytecode) which uses the .NET memory model is presented.
The verifier first verifies program under SC and then it explores additional runs allowed under .NET memory model.
It can also insert barriers into the program to avoid relaxed runs which violate given property (that is, not all relaxed runs are disabled by barriers but only those that actually lead to property violation).
The implementation of the exploration algorithm uses list of delayed instructions to implement instruction reordering, while the authors mention that the number of reordered instructions is not bounded, they do not discuss how this approach works for programs with cycles.

The work \cite{Dan2013} presents an approach for verification of (potentially infinite state space) programs under TSO and PSO using predicate abstraction.
The paper first shows that it is not possible to use traditional predicate abstraction to produce boolean program and then verify this boolean program using weak memory semantics.
Instead, they propose a schema which first verifies the program under SC and then extrapolates predicates from SC run to verify a transformed version of the original program which has store buffers explicitly encoded.
The store buffers are bounded in this transformation.
Implementation in the tool \textsc{cupex} is also provided, as well as evaluation on 7 programs which shows advantages of their predicate extrapolation method.

A completely different approach is taken in \cite{Turon2014}, this work introduces a separation logic GPS which allows proving properties about programs using the (fragment of) C11 memory model.
That is, this work is intended for manual proving of properties of parallel programs, not for automatic verification.
The memory models is not complete, it lacks relaxed and consume-release accesses.
