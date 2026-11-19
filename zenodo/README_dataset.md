# Gestión de residuos agrícolas y pecuarios en el Perú — datos de la ENA (Capítulo 600)

**Autores:** Angello Marcelo Zamora Valencia, Ronaldo Carlos Mamani Mena, Lizbeth Estefany Cáceres Tacora, Tania Karin Butrón Maquera (Universidad Nacional del Altiplano, Puno, Perú)
**Licencia:** CC BY 4.0 (datos derivados). Microdatos originales: © INEI, uso con citación de la fuente.
**Código asociado:** https://doi.org/10.5281/zenodo.YYYYYYY · https://github.com/USUARIO/ena-cap600-clustering

## Archivos

| Archivo | Descripción | Filas |
|---|---|---:|
| `FINAL_UNIFICADO.csv` | Extracto unificado original del Cap. 600, ENA 2014–2019 y 2022–2025 (47 columnas, UTF-8 con BOM) | 306 966 |
| `ena_cap600_15var.csv.gz` | Extracto depurado 2016–2025: identificadores, año, departamento, región, tamaño y 15 variables binarias (9 de residuos + 6 ilustrativas) | 244 609 |
| `ena_cap600_clusters.csv.gz` | Igual que el anterior + columna `CLUSTER` (1 = Aprovechamiento, 2 = Baja valorización, 3 = Abandono en campo) | 244 609 |
| `Diccionario_CAP600_variables_seleccionadas.xlsx` | Diccionario de las 47 variables originales y etiquetas | — |
| `diccionario_variables.md` | Definición de las 15 variables derivadas (rol activo/ilustrativo) | — |
| `tablas_resultados.zip` | Todas las tablas de resultados (CSV) | — |
| `checksums.md5` | Sumas de verificación MD5 | — |

## Notas
* Solo pequeños y medianos productores: el Cap. 600 se omite para grandes productores.
* No incluye factores de expansión: las proporciones describen la muestra.
* No hay encuesta en 2020–2021; las ediciones 2014–2015 se excluyeron del análisis (opciones de respuesta sobre residuos no comparables).
* Reglas de depuración: ver `docs/` del repositorio de código y la Sección III-B del artículo.
