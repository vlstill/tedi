---
vim: wrap linebreak nolist formatoptions-=t
---

Overall, the aim of my PhD research is to devise methods for efficient analysis of programs running under relaxed memory models.
These methods should also be implemented and thoroughly evaluated, aiming at real-world usability.
Namely, I would like to make it possible to apply relaxed-memory-aware analysis to unit tests of nontrivial parallel data structures and algorithms.
The implementation will be primarily working with the DIVINE model checker\ \cite{DIVINEToolPaper2017}.

# Objectives and Expected Results

## A LLVM-Based Program Transformation for Analysis of Relaxed Memory Models

A large number of verifiers and analysers with support for parallel programs lack support for relaxed memory models and assume sequential consistency.
While it is possible to extend these verifiers to relaxed memory models directly in many cases, we believe that an easier and more versatile path lies in transformation of the input formalism for these analysers, as done for example by \cite{Alglave2013}.
This way, the input program is transformed into another program which, when run under SC, simulates runs of the original program under a given relaxed memory model.

The most promising approach in this direction seems to be usage of the LLVM Intermediate Representation (LLVM IR) as the source and target for the transformation.
The choice of LLVM IR is justified by its wide use both by compilers (namely the clang compiler which can be used to compile C, C++, and Objective C on all major operating systems) and by a growing number of analysers: DIVINE\ \cite{DIVINEToolPaper2017} has support for both LLVM IR and parallelism, CPAchecker\ \cite{Beyer2011} has support for parallelism\ \cite{Beyer2016} and there are plans to add support for LLVM IR to it.
\TODO{LLBMC\ \cite{LLBMC}, KLEE\ \cite{KLEE}, and SMACK\ \cite{SMACK} already have support for LLVM IR, but they do not currently support parallelism without a sequentializers which pre-processes the input programs.}
Also, LLVM IR can be rather easily transformed as it is used for optimizations in the LLVM framework.

One of the advantages of the program transformation approach is that the same transformation (possibly with minor configuration) can be used for many analysers.
The transformation works by replacing memory operations with either fragments of code or calls to functions which provide implementation of a given operation under a relaxed memory model.
This also means that the same transformation, but with different implementations of memory operations, can be used to simulate different memory model, which makes this approach especially suitable for evaluation of different memory models and modes of their simulation.

There already exists a LLVM transformation which was developed for \cite{SRB15weakmem} and later extended for \cite{mgrthesis}.
This transformation is now being updated to remove its dependence on DIVINE-specific API.

Furthermore, there are many options in optimization of the transformation, e.g. it is not necessary to transform memory operations for which it can be proven that they only access thread-local data. The first of my aims is therefore optimization of this transformation which will be used as a basis for implementation of memory-model-aware analysis in DIVINE and possibly other verifiers.

## Implementation of Support for Several Important Memory Models

As already mentioned, the program transformation needs to be accompanied by implementation of memory model operations (memory model runtime).
The existing implementations for DIVINE \cite{SRB15weakmem, mgrthesis} support either TSO or a subset of the C++11 memory model, both of which use buffer bounding to limit state space explosion and achieve decidability while keeping the implementation simple.

We would like to implement framework for simulation of various memory models.
Namely the NSW memory model is significant for being decidable for programs with finite-state threads while also being more relaxed then PSO.
Also NSW is more relaxed then TSO and PSO memory models and therefore its implementation can be easily restricted and reused for verification under these memory models.
In addition to that, more relaxed memory models RMO, POWER and ARM should also be investigated.
Finally, we would like to re-visit the case of C/C++11/LLVM memory model once the framework of relaxed memory models offers sufficient relaxations to cover it fully.

At first, we will continue to use bounded data structures in the implementation of these memory models (therefore, devised methods will be sound, but not complete); however, we would also like to investigate extension of non-bounded, automata-based techniques outlined for example in \cite{Linden2010} to more relaxed memory models (\cite{Linden2010} supports only TSO).
Another area worth considering to recover completeness of decision procedures for NSW is usage of abstractions.
Both automata-based approach and abstractions will likely also require changes to the verification algorithm and therefore will not be implemented purely as program transformations accompanied by memory model runtime.

## Investigation of Different Data Structures for Simulation of Relaxed Memory Models

Furthermore, while there are many approaches for description of axiomatic semantics of memory models, it seems that operational semantics is generally described in terms of very simple data structures which, despite being used as basis for implementation of verification algorithms or program transformations, are not optimized for efficient implementation.
Therefore, we see opportunity in investigation of new data structures which can be used for implementation of memory model transformations and which would yield better performance for the resulting decision procedures.

Namely, the standard operational approach to TSO or PSO simulation is using store buffers which are filled by store operations and later non-deterministically flushed.
This approach means that there are states of the program in which the only difference is if a certain value is waiting in the store buffer or is already flushed to the memory.
If there is no thread to observe these differences, they are not significant an their only effect is in making programs' state space larger.
For this reason we would like to derive alternative operational semantics of NSW (and in that also TSO and PSO) which avoids the nondeterministic flushing of store buffers and resolves nondeterminism only in cases it is actually needed, i.e. at points when memory location is loaded.

## Optimization of State Space Exploration for Programs Running under Relaxed Memory in DIVINE

An important aspect for usability of automatic verification and analysis techniques such as model-checking is their ability to produce property violation witness (counterexample) in the case property violation is found.
However, usability of these counterexamples depends a lot on the exploration strategy employed by the analyser.
For relaxed memory models, it is desirable that counterexamples which contain least possible deviations from sequential consistency are found first.
Furthermore, it is expected that by directing exploration in this way, the algorithm will (on average,) run faster for programs which contain errors.

To this end, we would like to implement and evaluate algorithm for DIVINE which directs search by exploring sequentially consistent runs first and then gradually adds relaxations to the program.
It might be also possible to employ heuristics to direct relaxations so that it is first applied on variables on which it is more likely to cause property violations.

## Other sources of reordering

-   PO is not a total order

# Time Plan

The plan of the rest of my PhD study and research activities is following:

Now -- January 2018

~   Extension of the relaxed memory support in DIVINE to the NSW memory model.

January 2018

~   Doctoral exam and defense of this thesis proposal.

February 2018 -- May 2018

~   Development of heuristically directed search algorithm for verification under relaxed memory models in DIVINE.

July 2018 -- November 2018

~   Extension of relaxed memory support to POWER and ARM memory models, including development of transformation-friendly semantics of these memory models.

December 2018 -- January 2019

~   Extension of relaxed memory support to the C++/LLVM memory model.

February 2019 -- July 2019

~   Investigation and design of techniques for unbounded verification of programs running under relaxed memory models.

August 2019 -- January 2020

~   Text of the PhD thesis.

January 2020

~   The final version of the thesis.
