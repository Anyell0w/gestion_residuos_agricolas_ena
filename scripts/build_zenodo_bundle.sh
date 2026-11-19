#!/usr/bin/env bash
# Reúne en zenodo/upload/ los archivos del registro de DATOS para Zenodo.
set -euo pipefail
OUT="zenodo/upload"
rm -rf "$OUT"; mkdir -p "$OUT"
cp data/raw/FINAL_UNIFICADO.csv                         "$OUT/"
cp data/processed/ena_cap600_15var.csv.gz               "$OUT/"
cp data/processed/ena_cap600_clusters.csv.gz            "$OUT/"
cp data/dictionary/Diccionario_CAP600_variables_seleccionadas.xlsx "$OUT/"
cp docs/diccionario_variables.md                        "$OUT/"
cp zenodo/README_dataset.md                             "$OUT/README.md"
(cd outputs && zip -qr "../$OUT/tablas_resultados.zip" tables)
(cd "$OUT" && md5sum * > checksums.md5)
echo "Paquete listo en $OUT:"; ls -lh "$OUT"
