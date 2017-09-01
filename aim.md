---
vim: wrap linebreak nolist formatoptions-=t
---

Overall, the aim of my PhD research is to devise methods for efficient analysis of C and C++ programs running under relaxed memory models.
These methods should also be implemented and thoroughly evaluated, aiming at real-world usability.
Namely, I would like to make it possible to apply relaxed-memory-aware analysis to unit tests of nontrivial parallel data structures and algorithms.
The implementation will be primarily working with the DIVINE model checker \cite{DIVINEToolPaper2017}.

# Objectives and Expected Results

## An LLVM-Based Program Transformation for Analysis of Relaxed Memory Models

A large number of verifiers and analysers with support for parallel programs lack support for relaxed memory models and assume sequential consistency.
While it is possible to extend these verifiers to relaxed memory models directly in many cases, we believe that an easier and more versatile path lies in transformation of the input formalism for these analysers, as done for example by \cite{Alglave2013} or \cite{Abdulla2017}. 
This way, the input program is transformed into another program which, when run under SC, simulates runs of the original program under a given relaxed memory model.

The most promising approach seems to be the use of the LLVM Intermediate Representation (LLVM IR) as the source and the target for the transformation.
LLVM IR is widely used both by compilers (namely the clang compiler which can be used to compile C, C++, and Objective C on all major operating systems) and by a growing number of analysers with support for parallelism, for example DIVINE \cite{DIVINEToolPaper2017}, SMACK \cite{Rakamaric2014}, VVT \cite{Gunther2016}, Skink \cite{Cassez2017}, and Nidhugg \cite{Abdulla2015}.
Furthermore, CPAchecker\ \cite{Beyer2011} has support for parallelism\ \cite{Beyer2016} and there are plans to add support for LLVM IR to it.
Similarly, CBMC \cite{Clarke2004} has support for parallelism and planned support for LLVM.
Also, LLVM IR can be rather easily transformed as it is used for optimizations in the LLVM framework.

One of the advantages of the program transformation approach is that the same transformation can be used for many analysers.
The transformation works by replacing memory operations with either fragments of code or calls to functions which provide implementation of a given operation under a relaxed memory model.
This also means that the same transformation, but with different implementations of memory operations, can be used for evaluation of different memory models and modes of their simulation.

An initial LLVM transformation for relaxed memory models was developed for \cite{SRB15weakmem} and later extended for \cite{mgrthesis}.
This transformation is now being updated to remove its dependence on a DIVINE-specific API and make its interface more general to work with different memory model implementations.

Furthermore, there are many options in optimization of the transformation, e.g. it is not necessary to transform memory operations for which it can be proven statically that they only access thread-local data.
The first of my aims is therefore finishing this program transformation and its optimizations.
The transformation will be used as a basis for implementation of memory-model-aware analysis in DIVINE and possibly other verifiers.

## An Efficient Support for Non-Speculative Writes Memory Model

The program transformation needs to be accompanied by implementation of memory model operations (memory model runtime).
The existing implementations for DIVINE \cite{SRB15weakmem, mgrthesis} support either TSO or a subset of the C++11 memory model without read reordering, both of which use buffer bounding to limit the state space explosion and achieve decidability while keeping the implementation simple.

I would like to implement a framework for simulation of various memory models.
The first step in this direction will be to design an efficient operational model for the Non-Speculative Writes memory model.
This operational model should be designed so that it can be efficiently implemented and provide good performance for verification.

The NSW memory model was chosen as it is decidable for programs with a finite number of finite-state threads, it is more relaxed than PSO, and it should be possible to implement it reasonably efficiently.
To the best of our knowledge, the only operational semantics for NSW is given in \cite{Atig2012} where it is introduced.
However, while sufficient for proving its decidability, this semantics is not efficient for verification as it needs to resolve ordering of memory events eagerly, which leads to a lot of branching in the explored state space.
It also includes storing complete snapshots of memory in form of history buffers.
Instead, we would like to resolve ordering lazily only when actually needed, which should improve scalability of the analysis and to save only relevant parts of memory history.

At first, we will use bounded data structures in the implementation of NSW support.
Therefore, the resulting analysis algorithm will not be able to prove the absence of bugs as the number of instructions to be reordered will be bounded (but no other imprecisions will be introduced by this approach).
Nevertheless, we believe this approach is reasonable as it can uncover a large number of errors which would otherwise be hard to find.

## Heuristically-Directed Exploration Algorithm for Analysis under Relaxed Memory Models

An important aspect of usability of automatic verification and analysis techniques such as model checking is their ability to produce a property violation witness (counterexample) in case a property violation is found.
However, usability of these counterexamples depends a lot on the exploration strategy employed by the analyser.
For relaxed memory models, it is desirable that counterexamples which contain minimum possible number of deviations from sequential consistency are found first.

Furthermore, it is expected that by directing exploration to find less relaxed runs first, the algorithm will (on average) run faster for programs which contain errors.
It might be also possible to employ heuristics to direct relaxations so that relaxed behaviour is first applied on variables on which it is more likely to cause property violations.
Another possibility is using robustness-based heuristics and employ relaxed memory semantics only when needed, similar to \cite{Bouajjani2015}.

## Analysis of Very Weak Memory Models

The POWER and ARM memory models (which are quite similar) are important as they are very weak and there is increasing number of devices which use ARM processors and a good number of hi-performance devices powered by POWER.
However, these memory models come with relaxations such as writes which can propagate in different order to different processors and reordering of loads with succeeding writes which can lead to seemingly cyclic dependencies.
For this reason, these memory models are more subtle than NSW and require a more advanced analysis.

The C11 and C++11 standards came with a memory model designed to allow for an efficient multi-platform implementation of parallel primitives, even on very relaxed platforms such as POWER/ARM.
Therefore, the C++11 memory model is as over-approximation of the POWER/ARM memory models in the context of C/C++ programs, in the sense that all behaviours possible under POWER/ARM are also possible under the C++11 memory model.
A very similar memory model is also used by the LLVM intermediate language.
As DIVINE is an analyzer for C/C++, it is natural to have support for verification of programs under this memory model.

## Techniques for Unbounded Memory Model Analysis

Up to this point I expect to allow only bounded instruction reordering.
However, in order to increase coverage of our analysis, I would like to investigate techniques which allow unbounded reordering.
Such techniques could use some form of symbolic encoding of delayed memory operations, such as automata-based encoding introduced in \cite{Linden2010} (which supports only TSO), or they could use abstractions. Another possibility is using SMT-based symbolic encoding.
All of these approaches will likely also require changes to the verification algorithm and therefore will not be implemented purely as program transformations accompanied by memory model runtime.

# Time Plan

\begin{stretched}

The plan of the rest of my PhD study and research activities is following:

Now -- January 2018

~   Extension of the relaxed memory support in DIVINE to the NSW memory model and design of verification-friendly semantics for NSW.

January 2018

~   Doctoral exam and defense of this thesis proposal.

February 2018 -- June 2018

~   Development of heuristically directed search algorithm for verification under relaxed memory models in DIVINE.

June 2018 -- November 2018

~   Extension of relaxed memory support to more relaxed memory models such as C++, POWER and ARM memory models, including development of transformation-friendly semantics of these memory models.

December 2018 -- July 2019

~   Investigation and design of techniques for unbounded verification of programs running under relaxed memory models.

August 2019 -- January 2020

~   Text of the PhD thesis.

January 2020

~   The final version of the thesis.

\end{stretched}
