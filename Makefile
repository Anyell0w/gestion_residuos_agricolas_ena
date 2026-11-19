# ==================================================================
# Makefile — orquestación de extremo a extremo
#   make all       datos -> pipeline -> artículo
#   make pipeline  solo las 10 etapas de R
#   make paper     solo el PDF
# ==================================================================
export LANG := C.UTF-8
export LC_ALL := C.UTF-8
RAW := data/raw/FINAL_UNIFICADO.csv

.PHONY: all data pipeline paper zenodo clean distclean

all: pipeline paper

data: $(RAW)
$(RAW):
	bash scripts/download_data.sh

pipeline: $(RAW)
	Rscript run_pipeline.R

paper:
	$(MAKE) -C paper

zenodo: pipeline
	bash scripts/build_zenodo_bundle.sh

clean:
	rm -rf data/processed/* outputs/models/* logs/*
	$(MAKE) -C paper clean

distclean: clean
	rm -rf outputs/figures/* outputs/tables/* paper/figures/* paper/tables/* paper/main.pdf
