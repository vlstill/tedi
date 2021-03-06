---
vim: wrap linebreak nolist formatoptions-=t
---

Reasoning about the correctness of parallel programs is hard, even if we assume that every memory action a thread performs is visible to all other threads immediately, there is total ordering of these actions, and all loads read from the last write in this ordering.
Sadly, this assumption of *sequential consistency* of the memory does not hold in practice as both hardware and compilers perform optimizations which disrupt it.
These optimizations include instruction reordering in compilers and out-of-order processors and effects of cache hierarchies in the processors.
These techniques are vital for fast execution of all programs, not just parallel ones.
In the presence of these relaxations, memory changes can be observed in a different order by different threads.
It is the responsibility of the programmer to ensure that the program executes correctly by enforcing ordering of some operations, for example using memory barriers and atomic instructions of a given processor architecture, or using higher level constructs of a given programming language.

In many programming languages, this problem is partially mitigated by the presence of higher level constructs such as mutexes (locks) or synchronized sections of code.
These constructs, if used correctly, guarantee that the program will be executed as if running on hardware which preserves sequential consistency.
Nevertheless, programmers who design these synchronization constructs, operating systems, and hi-performance parallel data structures have to be aware of memory relaxations arising from the particular memory model.

To complicate matters further, different hardware platforms perform different relaxations of memory accesses -- for example, `x86` and `x86-64` (also known as AMD64) processors can only delay stores after loads, while ARM or POWER can also reorder writes with each other and reorder reads with writes arbitrarily (except for reordering of dependent writes).
Each platform also comes with a specific set of atomic instructions and memory barriers, which can be used to enforce operation ordering.
Therefore, in order to be able to have the same code work on different platforms, it is useful to have support for enforcing memory operation ordering in the programming language itself.
This support is also important as the compiler can reorder some operations while it optimizes the code and therefore it must be able to understand constructs that prevent such reordering, so they can prevent it both in the compiler and in the hardware.

Unfortunately, not all programming languages provide primitives related to memory relaxation or even define behaviour of parallel programs.
For example, C and C++ had no support for parallel programming until the respective standards from the year 2011.
In the older versions, parallelism was achieved only by means of libraries which provided thread manipulation and synchronization primitives (such as `pthreads` on POSIX systems) and memory ordering could have been controlled either by using these synchronization primitives or by compiler-provided language extensions.
Apart from the lack of standardized and multi-platform parallel programming support, the problem of this approach is that it is not clear which ordering guarantees arise from the program's code.
Other programming languages, such as Java, C#, C11, and C++11, have support for parallelism (including synchronization using mutexes and atomic variables) and their respective specifications describe what guarantees on memory operation ordering these languages provide.
It is then the responsibility of the compiler (and virtual machine in the case of Java/C#) to ensure these guarantees are met on any supported platform.

\bigskip

In this situation, we believe that study of memory relaxations all the way from the code in a programming language[^proglang] to the level of the hardware is important for the design of correct data structures and algorithms for parallel programs.
Furthermore, we believe this study should produce both descriptions of memory behaviour of programming languages and hardware platforms as well as tools which can help developers who design data structures and algorithms for these platforms.

[^proglang]: By *programming language* we understand higher-level languages in which code is mostly written by humans (e.g. C, C++, and Java) and distinguish them from *assembly languages*, which use platform-specific instructions and syntax, and from *intermediate languages*, which are used in some compilers mainly for platform-independent optimizations (e.g. LLVM IR).

In my PhD research, I would like to primarily focus on analysis of parallel programs running on hardware with relaxed memory semantics.
I would like to explore possibilities of efficient analysis of such programs which would be powerful enough to be usable to developers of hi-performance parallel data structures and algorithms.
Such analysis needs to be able to handle unit tests of real-world parallel data structures under relaxed memory models.
For these unit tests, it should be able to verify both unreachability of errors, as well as termination and preferably also general liveness properties (as given by linear temporal logic).
Furthermore, the analysis should be parametrized by the memory model and should support various hardware memory models and the memory model of the programming language.
As performance is often critical in parallel programs, I will focus on programs written in C and C++.

Providing a sound and complete decision procedure for memory models is not always possible, as all important problems are undecidable at least for some widespread memory models (more in \autoref{sec:decidability}).
Nevertheless, the introduced methods should be designed so that they give high confidence in the correctness of analysed programs.
The analysis should primarily be developed for the DIVINE model checker but should also be transferable also to other analysis tools.

\bigskip

The rest of this work is structured as follows: \autoref{chap:rmos} describes prominent memory models used in both hardware and programming languages.
\autoref{chap:verification} describes analysis and verification techniques for relaxed memory.
These two chapters together give an overview of the state-of-the-art.
\autoref{chap:aim} then presents aims of my future work and my time plan towards the thesis.
Finally, \autoref{chap:results} describes my research results in the area of analysis of parallel programs to date, including results not related to relaxed memory and \autoref{chap:publications} contains selection of my published papers.
