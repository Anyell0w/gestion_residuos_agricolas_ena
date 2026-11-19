#!/usr/bin/env bash
# Sustituye los DOI de marcador de posición por los DOI reales de Zenodo
# y el usuario de GitHub en todo el repositorio.
# Uso: bash scripts/set_doi.sh <ID_DATOS> <ID_CODIGO> <USUARIO_GITHUB>
#  p. ej.: bash scripts/set_doi.sh 15123456 15123999 angellozamora
set -euo pipefail
if [[ $# -ne 3 ]]; then
  echo "Uso: $0 <ID_ZENODO_DATOS> <ID_ZENODO_CODIGO> <USUARIO_GITHUB>" >&2; exit 1
fi
DATA_ID="$1"; CODE_ID="$2"; GH_USER="$3"
FILES=$(grep -rlE "XXXXXXX|YYYYYYY|USUARIO" --include="*.md" --include="*.tex" \
        --include="*.bib" --include="*.cff" --include="*.json" --include="*.sh" \
        --include="*.yml" --include="*.R" . | grep -v "scripts/set_doi.sh")
for f in $FILES; do
  sed -i.bak -e "s/XXXXXXX/${DATA_ID}/g" -e "s/YYYYYYY/${CODE_ID}/g" \
             -e "s/USUARIO/${GH_USER}/g" "$f" && rm -f "${f}.bak"
  echo "actualizado: $f"
done
echo "Listo. Recompile el artículo con: make paper"
