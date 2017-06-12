ALL=$(wildcard *.md)

all : thesis.pdf # archive_README.pdf

thesis.pdf : thesis.tex $(ALL:.md=.tex) thesis.bbl thesis.lua
	./latexwrap $<

thesis-print.pdf : thesis-print.tex $(ALL:.md=.tex) thesis-print.bbl thesis.lua
	./latexwrap $<

thesis-print.tex : thesis.tex
	sed -e 's/linkcolor={.*}/linkcolor={black}/' \
		-e 's/citecolor={.*}/citecolor={black}/' \
		-e 's/urlcolor={.*}/urlcolor={black}/' \
		-e 's/\\iffalse.*%@ifprint/\\iftrue/' \
		$< > $@

%.bbl : bibliography.bib %.bcf
	-biber $(@:.bbl=)

%.bcf :
	./latexwrap -n1 $(@:.bcf=.tex)

.PRECIOUS: %.bcf %.bbl

%.tex : %.md md2tex.pl Makefile
	perl -- md2tex.pl -f markdown -t latex < $< > $@

exvis.ll : exvis.cpp
	clang++ -std=c++14 -S -emit-llvm $< -O2

watch :
	while true; do inotifywait -e close_write,moved_to,create .; sleep 1; make; done

.PHONY: watch

archive_README.md : appendix.md
	sed $< -re 's/\\divine/DIVINE/g' -e 's/\\lart/LART/g' \
		-e 's/\\darcs/darcs/g' -e 's/\\llvm/LLVM/g' \
		-e 's/\\label\{[^}]*\}//g' > $@

archive_README.pdf : archive_README.md
	pandoc $< -o $@ -V geometry:a4paper,margin=2.5cm

txt: $(ALL:.md=.txt)

.PHONY: txt

%.txt : %.md
	sed -e ':a;N;$$!ba;s/\n\n/@NL@/g' $< | \
		sed -e ':a;N;$$!ba;s/\n/ /g' -e 's/@NL@/\n\n/g' \
			-e 's/\\autoref{[^}]*}//g' -e 's/\\//g' > $@

rawdata :
	mkdir -p rawdata/antea rawdata/aura rawdata/local
	rsync -avc --progress antea:/home/xstill/DiVinE/next/benchmark/ rawdata/antea/
	rsync -avc --progress aura:/home/xstill/DiVinE/next/benchmark/ rawdata/aura/
	rsync -avc --progress /home/xstill/DiVinE/mainline/benchmark/ rawdata/local/

.PHONY: rawdata


archive : thesis.pdf thesis-print.pdf
	rm archive llvmtrans -rf
	# make sure all links really link...
	make -B thesis.pdf thesis-print.pdf
	make -B thesis.pdf thesis-print.pdf
	mkdir archive
	cp thesis.pdf archive/
	mkdir llvmtrans
	cp README.md llvmtrans/
	cd llvmtrans && darcs get /home/xstill/DiVinE/next divine
	cp archive_README.md llvmtrans/divine/README.md
	cd llvmtrans && git clone https://github.com/vlstill/mgrthesis.git thesis
	cp thesis.pdf llvmtrans/thesis/
	rm llvmtrans/thesis/.git* -rf
	tar cavf llvmtrans.tar.gz llvmtrans
	mv llvmtrans.tar.gz archive

check :
	rm llvmtrans -rf
	tar xafv archive/llvmtrans.tar.gz
	cd llvmtrans/thesis && make
	cd llvmtrans/divine && chmod +x configure && ./configure && make lart divine

.PHONY: archive check
