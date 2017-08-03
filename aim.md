---
vim: wrap linebreak nolist formatoptions-=t
---

# Objectives and Expected Results

## A LLVM-Based Program Transformation for Analysis of Relaxed Memory Models

A large number of verifiers and analysers with support for parallel programs lack support for relaxed memory models and assume sequential consistency.
While it is possible to extend these verifiers to relaxed memory models directly in many cases, we believe that easier and more versatile path lies in transformation of the input formalism for these analysers, as done for example by \cite{Alglave2013}.
This way, the input program is transformed into another program which, when run under SC, simulates all runs of the original program under a given relaxed memory model.
The most promising approach in this direction seems to be usage of the LLVM Intermediate Representation (LLVM IR) as the source and target for the transformation.
The reason for choice of LLVM IR is that it is widely used both by compilers (namely the clang compiler which can be used to compile C, C++, and Objective C on all major operating systems) and by many analysers: to name a few DIVINE\ \cite{DIVINEToolPaper2017} \TODO{, LLBMC\ \cite{LLBMC}, KLEE\ \cite{KLEE}, and SMACK\ \cite{SMACK} already have support for LLVM *but not parallelism*} and there are also plans to add LLVM support into CPAchecker\ \cite{Beyer2011} which has recent support for parallel programs \cite{Beyer2016}.
Also, LLVM IR can be rather easily transformed as it is used for optimizations in the LLVM framework.

The main advantage of the program transformation approach is that the same transformation (possibly with minor configuration) can be used for many analysers.
The transformation works by replacing memory operations with either fragments of code or calls to functions which provide implementation of given operation under a relaxed memory model.
This also means that the same transformation, but with different implementations of memory operations, can be used to simulate different memory model, which makes this approach especially suitable for evaluation of different memory models and modes of their simulation.

There already exists a LLVM transformation which was developed for \cite{SRB15weakmem} and later extended for \cite{mgrthesis}.
However, this transformation needs to be updated and it is necessary to remove its dependence on DIVINE-specific API.

Furthermore, there are many options in optimization of the transformation, e.g. it is not necessary to transform memory operations for which it can be proven that they only access thread-local data.

## Implementation of Simulation for Several Important Memory Models

As already mentioned, the program transformation needs to be accompanied by implementation of memory model operations.
The existing implementations for DIVINE \cite{SRB15weakmem, mgrthesis} support either TSO or a subset of the C++11 memory model, both of which use buffer bounding to limit state space explosion and achieve decidability while keeping the implementation simple.

Therefore, we would like to implement framework for simulation of different memory models.
Namely the NSW memory model which is significant for being decidable for programs with finite-state threads.
Also NSW subsumes TSO and PSO memory models and therefore its implementation can be easily restricted and reused for verification under these memory models.
In addition to that, the more relaxed memory models RMO, POWER and ARM should also be investigated.
Finally, we would like to re-visit the case of C/C++11 memory model once the framework of relaxed memory models offers sufficient relaxations.

At first, we will continue to use bounded data structures in the implementation of these memory models; however, we would also like to investigate extension of non-bounded, automata-based techniques outlined for example in \cite{Linden2010} to more relaxed memory models (\cite{Linden2010} supports only TSO).

## Investigation of Different Data Structures for Simulation of Relaxed Memory Models

Furthermore, while there are many approaches for description of axiomatic semantics of memory models, it seems that operational semantics is generally described in terms of very simple data structures which, despite being used as basis for implementation of verification algorithms or program transformations, are not optimized for efficient implementation.
Therefore, we see opportunity in investigation of new data structures which can be used for implementation of memory model transformations.

Namely, the standard operational approach to TSO or PSO simulation is using store buffers which are filled by store operations and later non-deterministically flushed.
This approach, while simple means that there are states of the program in which the only difference is if a certain value is waiting in the store buffer or already flushed to the memory.
If there is no thread to observe these differences, they are not significant an their only effect is in making programs' state space larger.
For this reason we would like to derive alternative operational semantics of NSW (and in that also TSO and PSO) which avoids the nondeterministic flushing of store buffers and resolves nondeterminism only in cases it is actually needed, i.e. at points when memory location is loaded.

## Optimization of State Space Exploration for Programs Running under Relaxed Memory in DIVINE

An important aspect for usability of automatic verification and analysis techniques such as model-checking is their ability to produce property violation witness (counterexample) in the case property violation is found.
However, usability of these counterexamples depends a lot on the exploration strategy employed by the analyser.
For relaxed memory models, it is desirable that counterexamples which contain least possible deviations from sequential consistency are found first.
Furthermore, it is expected that by directing exploration in this way, the algorithm can also be, on average, faster for programs which contain errors.

To this end, we would like to implement algorithm for DIVINE which directs search by exploring sequentially consistent runs first and then gradually adds relaxations to the program.
It might be also possible to employ heuristics to direct relaxations so that it is first applied on variables on which it is more likely to cause property violations.

# Time Plan
