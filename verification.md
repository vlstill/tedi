---
vim: wrap linebreak nolist formatoptions-=t
---

As analysis and verification of parallel programs is desirable and memory models play important role in correctness of such programs, there are many techniques for analysis of parallel programs under various memory models. In this chapter, we will first look into decidability of common verification problems under relaxed memory models and then we will review some of these techniques. Such techniques can be split into two main areas, first area contains techniques which verify adherence of program to certain stronger memory model if it runs under other, weaker, memory model. For example, they can test that given program has no TSO-enabled runs which would be distinct from some SC runs. Some of these techniques also support fence insertion to restore stronger memory model. The second category contains techniques which check correctness of program (according to some property) under relaxed memory model (e.g. checking for assertion or memory safety, or checking for LTL properties). While the first category can be seen as a special case of the second, we consider the distinction important as the techniques from the first category are usually not used to prove absence of certain types of erroneous behavior, but just behavior which can be hard to analyze. Furthermore, in the second category, we consider both precise and approximative techniques.

# Decidability and Complexity of Memory Model Related Problems {#sec:decidability}

Right from the start it is important to note that even if we limit ourselves to programs with finite state space there are important problems in important memory models which are not decidable.

## Problem Definitions

### Reachability of Error State

In this case we ask if the program can reach an error (or goal) state from its initial state. Usually, there can be multiple error states which are given by some property which can be evaluated on each state separately, e.g. we can look for assertion violation or memory errors.

### Verification of Linear-Time Properties

An important class of properties are properties described by Linear Temporal Logic (LTL), \cite{TODO}. These properties are often considered especially in connection with reactive systems and explicit-state model checking \cite{TODO}. They allow users to specify properties such as reaction to certain even or repeated occurrence of certain event and they are evaluated on infinite runs of the program. With the automata-based approach to explicit-state model checking these problems are solved by solving repeated reachability of accepting states of \buchi product automaton derived from the program and the specification \cite{TODO}.

### Verification of Compliance of Hardware to Memory Model

There is also some work on verifying whether a hardware implements a given memory model. As this problem is not directly related to software verification, we will not consider such problems.

## Decidability and Complexity

According to \cite{wmdecidability} the problem of state reachability in finite-state concurrent programs under relaxed memory models is decidable for TSO and PSO memory models, but not for RMO. The repeated reachability, which can be used as basis for verification of LTL properties, is not decidable even for TSO. Nevertheless, the complexity of the state reachability in these programs under TSO is non-primitive recursive.

The proofs in \cite{wmdecidability} use a very simple program model with finite state control unit and simple memory actions. Furthermore, they assume that the number of memory locations and processes is fixed and that the data domain is finite. On the other hand, in practice both valid memory locations and processes can be created during the run of the program (and even though there is an upper bound of their number, this upper bound is not practical for use in analysis).

The proofs use reduction from TSO/PSO reachability to lossy channel machine reachability \cite{abdulla1996verifying} to prove decidability of these memory models, reduction from lossy channel machine reachability and repeated reachability \cite{abdulla1996undecidable} to TSO to prove that the reachability problem has non-elementary complexity and that the repeated reachability problem is undecidable and finally reduction from the Post's Correspondence Problem (PCP) \cite{post1946variant} to RMO reachability to prove its undecidability. Furthermore, from the construction of the reduction in the repeated reachability undecidability proof and from \cite{abdulla1996undecidable} it follows that LTL  and CTL model checking problem for TSO is also undecidable.

Due to the high complexity or undecidability of these problems, there are many approximative methods (see \autoref{sec:analysis:approx}) or methods which combine verification of adherence to sequential consistency with verification of absence of errors under sequential consistency (see \autoref{sec:analysis:adherence}). Furthermore, there are some methods which are precise for acyclic programs, but might not terminate or are only approximative in general \cite{Bouajjani2015, Alglave2013?}.

*   \cite{Atig2012}

# Verification of Absence of SC Violations {#sec:analysis:adherence}

As the reachability problem for programs under relaxed memory models is either very expensive to solve or undecidable, an alternative approach was proposed which builds on combination of analysis under sequential consistency with a procedure which verifies that no runs under the given relaxed memory model expose behavior not exposed under SC \cite{Burckhardt2008}. The second part of this task is described by the robustness problem, which is explored under many names, e.g. \cite{Burckhardt2008} uses notion of TSO-safety, \cite{Bouajjani2013} uses notion of robustness, and \cite{Alglave2011} uses notion of stability. The advantage of this combination is that, at least for some memory models, it has significantly lower complexity than the reachability problem. For example, in the case of finite-state process the TSO robustness problem is in $\mathrm{PSPACE}$, the same complexity class as the SC reachability problem. Therefore, robustness based verification of finite state processes under TSO is in $\mathrm{PSPACE}$ which TSO reachability is non-elementary.

However, the disadvantage of these techniques is that for correctness analysis of parallel programs they can vastly over-approximate possible errors as in practice it is often desirable to allow relaxed behavior provided it does not lead to an error.

The works \cite{Burckhardt2008, Burnim2011} build on detecting TSO (in the case of \cite{Burckhardt2008}, tools SOBER) or both TSO and PSO (\cite{Burnim2011}, tool THRILLE) violations by monitoring sequentially consistent executions of programs. A more general notion of stability (which relates two arbitrary memory models) is used in \cite{Alglave2011} which explores recovering of SC from `x86` or POWER memory model. The work also presents the tool \textsf{offence} which inserts synchronization into `x86` or POWER assembly to ensure stability. Another approach for detecting non-SC behaviour (under TSO) is presented in \cite{Bouajjani2013}. This approach uses a notion of *attacks*, a form of restricted out-of-order execution which witnesses SC violation. Authors also provide implementation in tool \textsc{Trencher} which uses SC model checker, Spin \cite{Holzmann1997}, as a backend for validation of attacks.

# Fence Insertion Techniques

# Precise Verification Techniques {#sec:analysis:precise}

*     \cite{Abdulla2012}

# Approximative and Bug Finding Techniques {#sec:analysis:approx}

There are many techniques for analysis of programs under relaxed memory models which fall into the category of bug finding tools -- such tools are unable to prove correctness in general, but they provide substantially better coverage of possible behaviors of parallel program then testing.

*   \cite{Alglave2013} -- `x86`, POWER/ARM - parametrized, code transformation,
    sound but not complete (buffer bounding, loop bounding (if using BMC),
    probably not full RMO), general both in memory model and in tools used as
    backend, Coq proof that operational semantics matches
    \cite{Alglave2010_fences}. C/goto-programs.

*   \cite{Bouajjani2015} -- introduces TSO lazily by iterative refinement, not
    complete but should eventually find all errors. Based on robustness checker of \cite{Bouajjani2013}. Special language, tool \textsc{Trencher}.
