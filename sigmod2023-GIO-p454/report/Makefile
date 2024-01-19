all: clean create

create:
	latexmk -pdf -silent -synctex=1 Report.tex
	#pdflatex Report.tex

clean:
	rm -rf *.aux  *.nav  *.vrb  *.log  *.out *.snm *.toc *.gz *.mtc* *.maf *.fls *.tmp *.bbl *.blg  *.mtc  *.bcf *.xml *.dvi *.xcp *.fdb_latexmk *.tps *.auxlock
