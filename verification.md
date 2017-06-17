---
vim: wrap linebreak nolist formatoptions-=t
---

As analysis and verification of parallel programs is desirable and memory models play important role in correctness of such programs, there are many techniques for analysis of parallel programs under various memory models. In this chapter, we will first look into decidability of common verification problems under relaxed memory models and then we will review some of these techniques. Such techniques can be split into two main areas, first area contains techniques which verify adherence of program to certain stronger memory model if it runs under other, weaker, memory model. For example, they can test that given program has no TSO-enabled runs which would be distinct from some SC runs. Some of these techniques also support fence insertion to restore stronger memory model. The second category contains techniques which check correctness of program (according to some property) under relaxed memory model (e.g. checking for assertion or memory safety, or checking for LTL properties). While the first category can be seen as a special case of the second, we consider the distinction important as the techniques from the first category are usually not used to prove absence of certain types of erroneous behavior, but just behavior which can be hard to analyze. Furthermore, in the second category, we consider both precise and approximative techniques.

# Decidability and Complexity of Memory Model Related Problems

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

\TODO{the reduction assumes finite number of memory locations and fixed number of processes}

Due to the high complexity or undecidability of these problems, there are many approximative methods (see \autoref{sec:analysis:approx}) or methods which combine verification of adherence to sequential consistency with verification of absence of errors under sequential consistency (see \autoref{sec:analysis:adherence}). Furthermore, there are some methods which are precise for acyclic programs, but might not terminate or are only approximative in general \cite{Bouajjani2015, Alglave2013?}.



# Verification of Adherence to Memory Model {#sec:analysis:adherence}

# Precise Techniques {#sec:analysis:precise}

# Approximative Techniques {#sec:analysis:approx}
