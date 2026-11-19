# Compila el artículo: pdflatex -> bibtex -> pdflatex x2
TEX = main
all: $(TEX).pdf
$(TEX).pdf: $(TEX).tex references.bib tables/*.tex figures/*.pdf
	pdflatex -interaction=nonstopmode -halt-on-error $(TEX).tex
	bibtex $(TEX)
	pdflatex -interaction=nonstopmode -halt-on-error $(TEX).tex
	pdflatex -interaction=nonstopmode -halt-on-error $(TEX).tex
clean:
	rm -f *.aux *.bbl *.blg *.log *.out *.toc
.PHONY: all clean
