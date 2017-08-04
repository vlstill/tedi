---
vim: wrap linebreak nolist formatoptions-=t
---

My work so far was mostly concerned with the DIVINE model checker \cite{DIVINEToolPaper2017}.
It started during my bachelor studies with techniques for compression of state space, which resulted in publication \cite{RSB15TC}.
During my master's study, my work included heuristics for state space exploration \cite{SRB14CSDR} and transfromations of LLVM Intermediate Reprezentation \cite{SRB15weakmem, mgrthesis}.
These transformations included optimizations which can lead to more efficient verifications and first transformations for relaxed memory models.

During my PhD work, I fist focused mostly on general verification of parallel C and C++ programs.
This included revised support for C++ exceptions \cite{SRB2017except} and a lot of work on the new version of DIVINE which mostly had character of implementation \cite{DIVINEToolPaper2017}.

# Published Papers

\newcommand{\fcite}[1]{\fullcite{#1}~\cite{#1}}

*   \fcite{BBH+13DIVINE}

     Tool paper for DIVINE 3, I have minor contribution to implementation for this paper.

*   \fcite{SRB14CSDR}

    I have made implementation and evauation for this paper as well as part of the text.

*   \fcite{RSB15TC}

    I have made part of the implementation (most concerning compression scheme for model checker states and its integration to DIVINE), full evaluation and part of the text.

*   \fcite{BRSW15HS}

    I have minor contributions to this paper.

*   \fcite{SRB15weakmem}

    I am main author of this paper, I have made most of the implementation, full evaluation, and most of the text.

*   \fcite{BCRSZ16Prob}

    I have provided small part of the implementation (concerning export of state
    space from DIVINE) and text concerning this part for the paper.

*   \fcite{SRB16SVC}

    Competition contribution for SV-COMP 2016 \cite{SV-COMP:2016}.
    I am primary author of this paper, I have written most of the text as well
    as implemented all modifications which were needed for participation of
    DIVINE in SV-COMP 2016.

*   \fcite{MJSLB2017}

    Competititon contribution for SV-COMP 2017 \cite{SV-COMP:2017}. I have made minor contributions to this paper.

*   \fcite{SRB2017except}

    I am primary author of this paper, I have written most of the text and implmementation for exception support in DIVINE 4 as well as performed the evaluation for this paper.

*   \fcite{DIVINEToolPaper2017}

    Tool paper for DIVINE 4, I have written most of the text for this paper.
