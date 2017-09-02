---
vim: wrap linebreak nolist formatoptions-=t
---

Development of parallel programs comes with many pitfalls as it requires reasoning about interaction of threads and safety of communication.
Furthermore, testing is not much helpful for bugs dependent on scheduling nondeterminism.
To make matters worse, contemporary hardware uses relaxed memory semantics: instructions can be reordered by out-of-order execution and memory effects can be further delayed by cache hierarchy.
This means that the natural interleaving model of parallelism used both by developers and many formal analysis tools does not expose all possible executions of the program.
The problem is further complicated by the fact that different hardware platforms have different memory models which allow various levels of instruction reordering.

This PhD thesis proposal is dedicated to the problem of analysis of parallel programs running on hardware with relaxed memory semantics.
It first presents the state-of-the-art in description of memory models and in analysis techniques which take them into account.
It further presents goals for the rest of my PhD studies, concretely devising methods for efficient analysis of C and C++ programs running under relaxed memory models.
These analysis techniques should be applicable to unit tests of parallel synchronization primitives, data structures, and algorithms.
All the techniques will be implemented in the DIVINE model checker.
Finally, the thesis proposal summarises my achieved results.
