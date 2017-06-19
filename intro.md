---
vim: wrap linebreak nolist formatoptions-=t
---

Reasoning about the correctness of parallel programs is hard, even if we assume that every memory action a thread performs is visible to all other threads at once, and any run of the program can be seen as an interleaving of these actions. Sadly, this assumption, known as sequential consistency, does not hold in practice as both hardware and compilers perform optimizations which go against sequential consistency.

In order to increase execution speed for parallel programs that access the same memory concurrently, modern CPUs use techniques such as store buffering or invalidation queues which lead to relaxation of memory accesses. In presence of such relaxations, writes to memory can be observed in a different order in different threads. It is then the responsibility of the programmer to ensure program executes correctly by enforcing ordering of come operations, for example using memory barriers, atomic instructions of given CPU, or higher level constructs of a given programming language.

In many programming languages, the problem is partially mitigated by the presence of higher level constructs such as mutexes or synchronized sections of code which, if used correctly, guarantee program will be executed as if running on hardware which preserves sequential consistency. Nevertheless, programmers who design these synchronization constructs, operating systems, and hi-performance parallel data structures have to be aware of memory relaxations.

To complicate matters further, different hardware platforms perform different relaxations of memory accesses -- for example, Intel `x86` and AMD64 can only delay stores after loads, while ARM or POWER can also reorder writes with each other and reorder reads with writes arbitrarily (except for reordering of dependent writes). Each platform also comes with a specific set of atomic instructions and memory barriers which can be used to enforce operation ordering. Therefore, in order to be able to have the same code work on different platforms, it is necessary to have support for enforcing memory operation ordering in the programming language itself. Furthermore, this support is also important as the compiler can reorder some operations while it optimizes the code and therefore it must be able to understand constructs that prevent such reordering, so they can prevent it both in the compiler and in the hardware.

Sadly, not all programming languages provide primitives related to memory relaxation. For example, C and C++ had no support for parallel programming until the respective standards from 2011, and parallelism was achieved only by means of libraries which provided thread manipulation and synchronization primitives (such as `pthreads`) and memory ordering could have been controlled either by using these synchronization primitives or by using compiler-provided language extensions. Apart from a lack of standardized and multi-platform parallel programming support, the problem of this approach is that it is not clear which ordering guarantees arise from the program code. Other programming languages, such as Java, C11, and C++11, have support for parallelism and their respective specifications describe what guarantees on memory operation ordering do these languages provide. It is then the responsibility of the compiler (or virtual machine in the case of Java) to ensure these guarantees are met on the given platform.


\bigskip

In this situation, we believe that study of memory relaxations all the way from the code in a programming language[^proglang] to the level of the hardware is important for the design of correct data structures and algorithms for parallel programs. Furthermore, we believe this study should produce both descriptions of memory behavior of programming languages and hardware platforms as well as tools which can help developers in design of data structures and algorithms for these platforms.

[^proglang]: By *programming language* we understand higher-level languages in which code is mostly written by humans (e.g. C, C++, and Java) and distinguish them from *assembly languages* which use platform-specific instructions and syntax, and from *intermediate languages* which are used in some compilers mainly for platform-independent optimizations (e.g. LLVM IR).

*   \TODO{obecný popis memory modelů + nastínit cíle + motivace}

\bigskip

The rest of this work is structured as follows: the \autoref{chap:rmos} describes hardware constructs which give rise to relaxed memory, different memory models used to describe these relaxations, and connection to programming languages. \autoref{chap:verification} describes analysis and verification techniques for relaxed memory. These two chapters together give an overview of the state-of-the-art. \autoref{chap:results} then describes my research results, including results not related to relaxed memory. Finally, \autoref{chap:aim} presents aims of my future work and \autoref{chap:conclusion} concludes this work.
