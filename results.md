---
vim: wrap linebreak nolist formatoptions-=t
---

My work so far has been mostly concerned with analysis of parallel programs and the DIVINE model checker \cite{DIVINEToolPaper2017}.
It started during my bachelor studies with techniques for compression of state space, which resulted in publication \cite{RSB15TC}.
During my master's study, my work included heuristics for state space exploration \cite{SRB14CSDR} and transfromations of LLVM Intermediate Reprezentation \cite{SRB15weakmem, mgrthesis}.
These transformations included optimizations which can lead to more efficient verifications and transformations for relaxed memory models.

During my PhD work, I fist focused mostly on general verification of parallel C and C++ programs.
This included revised support for the C++ exceptions in DIVINE \cite{SRB2017except} and a lot of work on the new version of DIVINE which mostly had character of implementation and resulted in a tool paper \cite{DIVINEToolPaper2017}.

# Published Papers

\newcommand{\fcite}[1]{\emergencystretch 3em\fullcite{#1}~\cite{#1}}

*   \fcite{BBH+13DIVINE}

     Tool paper for DIVINE 3, I have minor contribution to implementation of DIVINE 3 which is described in this paper.

*   \fcite{SRB14CSDR}

    This paper shows that directing search to first explore runs with low number of context switches can improve performance of the verifyer as well as improve the counterexamples.
    I have made implementation and evauation for this paper as well as written part of the text.
    I have also presented this paper on the MEMICS 2014 conference.

*   \fcite{RSB15TC}

    This paper describes techniques which lead to better memory efficiency of verification of parallel programs in an explicit-state model checker.
    These techniques include a tree-based compression scheme for state space storage and a custom allocation scheme.
    I have made part of the implementation (concerning the compression scheme), full evaluation and part of the text.
    I have also presented this paper on the SEFM 2015 conference.

*   \fcite{BRSW15HS}

    This paper describes efficient design of a concurrent hash table used in DIVINE.
    I have minor contributions to this paper.

*   \fcite{SRB15weakmem}

    This paper describes the approach to analysis of programs under the TSO memory model using LLVM transformation.
    I am main author of this paper, I have made most of the design and implementation, full evaluation, and most of the text.
    I have also presented this paper on the MEMICS 2015 conference.

*   \fcite{BCRSZ16Prob}

    This paper describes chaining of DIVINE (which was extended to allow annotation of edges with probabilities) with the PRISM model checker to allow probabilistic analysis.
    I have provided small part of the implementation (concerning export of state
    space from DIVINE) and text concerning this part for the paper.

*   \fcite{SRB16SVC}

    Competition contribution for SV-COMP 2016 \cite{SV-COMP:2016}.
    This paper shortly describes DIVINE and the specifics of applying it to the concurrency category of SV-COMP.
    I am primary author of this paper, I have written most of the text as well as implemented all modifications of DIVINE which were needed for participation in SV-COMP 2016.
    I have also had short presentation of this paper in the SV-COMP session of the ETAPS/TACAS 2016 conference.

*   \fcite{MJSLB2017}

    Competititon contribution for SV-COMP 2017 \cite{SV-COMP:2017}.
    This paper shortly describes tool SymDIVINE which combines explict and symbolic approach to verficiation of parallel programs.
    I have made minor contributions to this paper.

*   \fcite{SRB2017except}

    This paper describes the approach we took towards verification of C++ code with exceptions in DIVINE 4.
    We show that carefully selecting which components of existing implementations and libraries to reuse and which to reimlement allowed us to provide full C++ exception support in DIVINE without much cost in terms of runtime performace, implementation effort or increase of complexity of the verifier.
    I am primary author of this paper I have written most of the text and implmementation for exception support in DIVINE 4 as well as performed the evaluation for this paper.
    I have also presented this paper on the QRS 2017 conference.
    The paper and its presentation was awareded with the best paper award.

*   \fcite{DIVINEToolPaper2017}

    Tool paper describing architecture of DIVINE 4 and new features of this version.
    I have written most of the text for this paper.
