#!/usr/bin/env bash
# Descarga el CSV crudo desde el registro de Zenodo (datos).
# Registro: https://doi.org/10.5281/zenodo.24371365
set -euo pipefail
RECORD="24371365"
DEST="data/raw/FINAL_UNIFICADO.csv"
EXPECTED_MD5="$(cat data/raw/FINAL_UNIFICADO.csv.md5 2>/dev/null | cut -d' ' -f1 || true)"
mkdir -p data/raw
if [[ "$RECORD" == "XXXXXXX" ]]; then
  echo "Aún no se ha configurado el registro de Zenodo (ejecute scripts/set_doi.sh)." >&2
  echo "Copie manualmente FINAL_UNIFICADO.csv en data/raw/." >&2
  exit 1
fi
curl -fL "https://zenodo.org/records/${RECORD}/files/FINAL_UNIFICADO.csv?download=1" -o "$DEST"
if [[ -n "$EXPECTED_MD5" ]]; then
  echo "${EXPECTED_MD5}  ${DEST}" | md5sum -c -
fi
echo "Datos descargados en ${DEST}"
