ALL=$(wildcard *.md) publications.tex
PAPERS=atva2017.pdf memics2015.pdf qrs2017.pdf sefm2015.pdf

all : thesis.pdf

thesis.pdf : thesis.tex $(ALL:.md=.tex) thesis.bbl $(PAPERS)
	./latexwrap $<

thesis-print.pdf : thesis-print.tex $(ALL:.md=.tex) thesis-print.bbl $(PAPERS)
	./latexwrap $<

thesis-print.tex : thesis.tex
	sed -e 's/linkcolor={.*}/linkcolor={black}/' \
		-e 's/citecolor={.*}/citecolor={black}/' \
		-e 's/urlcolor={.*}/urlcolor={black}/' \
		-e 's/\\iffalse.*%@ifprint/\\iftrue/' \
		$< > $@

%.bbl : thesis.bib %.bcf
	-biber $(@:.bbl=)

%.bcf :
	./latexwrap -n1 $(@:.bcf=.tex)

.PRECIOUS: %.bcf %.bbl

%.tex : %.md md2tex.pl Makefile
	perl -- md2tex.pl -f markdown -t latex < $< > $@

watch :
	while true; do inotifywait -e close_write,moved_to,create .; sleep 1; make; done

.PHONY: watch

atva2017.pdf :
	wget -O $@ https://paradise.fi.muni.cz/publications/pdf/DIVINEToolPaper2017.pdf
	
qrs2017.pdf :
	wget -O $@ https://paradise.fi.muni.cz/publications/pdf/SRB2017.pdf

memics2015.pdf :
	wget -O $@ https://paradise.fi.muni.cz/publications/pdf/SRB15weakmem.pdf
	
sefm2015.pdf :
	wget -O $@ https://paradise.fi.muni.cz/publications/pdf/RSB15TC.pdf
