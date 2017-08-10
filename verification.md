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

## Problem Definitions

#### Reachability of Error State

In this case we ask if the program can reach an error (or goal) state from its initial state. 
In practice, there can be multiple error states which are given by some property which can be evaluated on each state separately, e.g. we can look for assertion violation or memory errors. 

#### Verification of Linear-Time Properties

An important class of properties are properties described by Linear Temporal Logic (LTL), \cite{TODO}.
These properties are often considered especially in connection with reactive systems and explicit-state model checking \cite{TODO}. 
They allow users to specify properties such as reaction to certain event or repeated occurrence of an event and they are evaluated on infinite runs of the program.
With the automata-based approach to explicit-state model checking these problems are solved by solving repeated reachability of accepting states of \buchi product automaton derived from the program and the specification \cite{TODO}.

#### Verification of Compliance of Hardware to Memory Model

There is also some work on verifying whether a hardware implements a given memory model.
As this problem is not directly related to software verification, we will not consider such problems.

## Decidability and Complexity Results

According to \cite{wmdecidability} the problem of state reachability in concurrent programs with finite-state processes under relaxed memory models is decidable for TSO and PSO memory models, but not decidable for RMO.
The repeated reachability, which can be used as basis for verification of LTL properties, is not decidable even for TSO.
Nevertheless, the complexity of the state reachability in these programs under TSO and PSO is non-primitive recursive.
In \cite{Atig2012}, these decidability finding are further refined: a more relaxed decidable memory model, Non-Speculative Writes (NSW) is identified, and stronger claim about undecidability is proven, showing that adding relaxation which allows reordering reads after subsequent writes to TSO brings undecidability.

The proofs in \cite{wmdecidability} use a very simple program model with finite-state control unit and simple memory actions.
Furthermore, they assume that the number of memory locations and processes is fixed and that the data domain is finite.
On the other hand, in practice both valid memory locations and processes can be created during the run of the program (and even though there is an upper bound of their number, this upper bound is not practical for use in analysis).

The proofs use reduction from TSO/PSO reachability to lossy channel machine reachability \cite{abdulla1996verifying} to prove decidability of these memory models, reduction from lossy channel machine reachability and repeated reachability \cite{abdulla1996undecidable} to TSO to prove that the reachability problem has non-elementary complexity and that the repeated reachability problem is undecidable and finally reduction from the Post's Correspondence Problem (PCP) \cite{post1946variant} to RMO reachability to prove its undecidability.
Furthermore, from the construction of the reduction in the repeated reachability undecidability proof and from \cite{abdulla1996undecidable} it follows that LTL  and CTL model checking problem for TSO is also undecidable.

# Verification of Absence of SC Violations {#sec:analysis:adherence}

As the reachability problem for programs under relaxed memory models is either very expensive to solve or undecidable, an alternative approach was proposed which builds on combination of analysis under sequential consistency with a procedure which verifies that no runs under the given relaxed memory model expose behavior not exposed under SC \cite{Burckhardt2008}.
The second part of this task is explored under many names, e.g. \cite{Burckhardt2008} uses notion of TSO-safety, \cite{Bouajjani2013} uses notion of robustness, and \cite{Alglave2011} uses notion of stability.
The advantage of this combination is that, at least for some memory models, it has significantly lower complexity than the error reachability problem.
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

*   \cite{Alglave2013} -- `x86`, POWER/ARM - parametrized, code transformation,
    sound but not complete (buffer bounding, loop bounding (if using BMC),
    probably not full RMO), general both in memory model and in tools used as
    backend, Coq proof that operational semantics matches
    \cite{Alglave2010_fences}. C/goto-programs.

*   \cite{Atig2011} -- Program transformation, instead of store buffers it uses
    additional copies of shared variables (the used language distinguished shared and thread-local variables).
    It is bounded not in the size of the buffers (which are not encoded) but in number of context switches (two versions: total number of context switches is bounded, number of contexts switches the values is delayed is bounded). The memory model is \TODO{TODO}.

*   \cite{Abdulla2017} -- Context bounded analysis for the POWER architecture, by transformation of program.
    Uses nondeterminism heavily to guess result of sequence of instructions which is later checked.
    CBMC is used as a backend.
    It shows that context bounded analysis for POWER is decidable. 
    Tool `power2sc`, compared with goto-instrument and niddhug.
    Evaluation on C programs.
    In a way extension of \cite{Atig2011}.

*   \cite{Bouajjani2015} -- introduces TSO lazily by iterative refinement, not
    complete but should eventually find all errors. Based on robustness checker
    of \cite{Bouajjani2013}. Special language, tool \textsc{Trencher}.

*     \cite{Abdulla2012} -- encoding of NSW to hierarchical store buffers +
      history buffer, decidability proof without direct algorithm

*   \cite{Linden2010} -- TSO, buffers represented by automata, without buffer
    bounds, cycle iteration acceleration (for cycles involving changes in only one SB), uses sleep set POR which actually looks reasonable and aplicable to DIVINE due to crude definition of independence, verifies modified Promela, standalone implementation in Java. It is not clear if the algorithm is guaranteed to terminate.

*   \cite{Park1995} -- Explores SPARC hierarchy of memory models (TSO, PSO,
    RMO), modelled using encoding from assembly to Mur$\varphi$.
    The encoding allows all reordering of instructions allowed by given memory model (modulo bounds).
    Bounded in number of reorderings. Targeted add small synchronization primitives such as spin locks.

*   \cite{Dan2013} -- Presents an approach for verification of (potentially infinite state space) programs under TSO and PSO using predicate abstraction.
    The paper first shows that it is not possible to use traditional predicate abstraction to produce boolean program and then verify this boolean program using weak memory semantics.
    Instead, they propose a schema which first verifies the program under SC and then extrapolates predicates from SC run to verify a transformed version of the original program which has store buffers explicitly encoded.
    The store buffers are bounded in this transformation.
    Implementation in the tool \textsc{cupex} is also provided, as well as evaluation on 7 programs which shows advantages of their predicate extrapolation method.

*   \cite{Huynh2006} -- Presents explicit state model checker for C# programs (supporting subset of C#/.NET bytecode) which uses the .NET memory model.
 The verifier first verifies program under SC and then it explores additional runs allowed under .NET memory model.
 It can also insert barriers into the program to avoid relaxed runs which violate given property (that is, not all relaxed runs are disabled by barriers but only those that actually lead to property violation).
 The implementation of the exploration algorithm uses list of delayed instructions to implement instruction reordering.
 While the authors mention that the number of reordered instructions is not bounded, they do not discuss how this approach works for programs with cycles.

*   \cite{Zhang2015} -- Stateless model checking for TSO and PSO, modelling nondeterminism from both
    scheduling and store buffering in common framework.
    This is done by adding store buffers to the program and adding shadow thread for each store bufer which is responsible for flushing contents of this buffer to the memory.
    This simulation of memory models is accompanied by exploration algorithm which uses stateless model checking \cite{Godefroid1997} and dynamic partial order reduction \cite{Flanagan2005dpor}.
    Therefore, the algorithm is either limited to programs which terminate.
    The work is mostly concerned with adapting stateless model checking with DPOR to TSO and PSO.
    Both unboonded and with buffer mounding. Tool *rInspect* (LLVM based).

*   \cite{Abdulla2015} -- Executions represented by chronological traces which capture dependencies required to represent interaction between memory actions.
    Optimal DPOR -- explore exactly one execution in the equivalence class of the partial order.
    For robust programs, using the optimal DPOR algorithm with chronological traces should produce the same number of executions under SC as under relaxed memory model.
    Implemented SMC, for C/pthreads, with bounded execution length.
    Implemented in Niddhugg (LLVM based).

*   \cite{Norris2013} -- A stateless model checking approach to the C++11 memory model (with the exception of release-consume synchronization).
    Uses custom implementation of C++ thread and atomic libraries to produce binary which performs the analysis.
    Based on lazy building of relations between memory operations in the form of the *modification order graph*.
    This both prevents exploration of infeasible executions as well as unnecessary distinction between equivalent executions.
    Futhermore, as the C++ memory model allows reordering of reads with future operation, the proposed technique allows this by propagating stored values to previous loads and validating this speculation.
    The paper includes a long discussion about features of the C++ memory model and the correcponding implementation in \textsc{CDSChecker}.
    The tool \textsc{CDSChecker}, is usable for (small) unit tests of concurrent data structures.

*   \cite{Turon2014} -- Introduces a separation logic GPS which allows proving properties about programs using the (fragment of) C11 memory model.
    The memory models is restricted to non-atomic, acquire-release, and sequentially consistent accesses -- i.e. it lacks support for relaxed and consume-release accesses.
