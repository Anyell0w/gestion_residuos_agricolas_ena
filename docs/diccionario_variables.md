# Diccionario de variables

## A. Variables originales utilizadas (ENA, Capítulo 600)

Ver `data/dictionary/Diccionario_CAP600_variables_seleccionadas.xlsx` para las 47 variables y sus etiquetas. Variables de identificación usadas: `ANIO`, `CCDD`, `CCPP`, `CCDI`, `UA`, `RESFIN` (1 completa), `REGION` (1 Costa, 2 Sierra, 3 Selva; 4 no documentado → Costa), `CODIGO` (1 pequeño/mediano, 2 grande), `OMICAP600`.

**Periodo analizado:** 2016–2025. Las ediciones 2014–2015 se excluyen porque sus opciones de respuesta de P601/P602 no son comparables (ver `outputs/tables/armonizacion_anual.csv`).

## B. Las 15 variables del estudio (binarias: 1 = sí, 0 = no)

Las 9 variables **activas** (gestión de residuos) definen los grupos; las 6 **ilustrativas** solo los describen.

| # | Variable | Rol | Bloque | Definición | Regla desde el cuestionario | Prevalencia | DE |
|---:|---|---|---|---|---|---:|---:|
| 1 | `RC_QUEMA` | Activa | Residuos de cultivo | Residuos de cultivo: quema | `P601_1` | 18.4 % | 0.387 |
| 2 | `RC_ALIMENTO` | Activa | Residuos de cultivo | Residuos de cultivo: alimento animal | `P601_2` | 24.3 % | 0.429 |
| 3 | `RC_BOTA` | Activa | Residuos de cultivo | Residuos de cultivo: bota | `P601_3` | 4.1 % | 0.198 |
| 4 | `RC_ABONO` | Activa | Residuos de cultivo | Residuos de cultivo: abono | `P601_4` | 26.0 % | 0.438 |
| 5 | `RC_CAMPO` | Activa | Residuos de cultivo | Residuos de cultivo: deja en campo | `P601_5` | 71.7 % | 0.450 |
| 6 | `RA_INADEC` | Activa | Residuos pecuarios | Residuos pecuarios: quema/entierra/bota | `P602_1 | P602_2 | P602_3` | 12.9 % | 0.336 |
| 7 | `RA_ABONO` | Activa | Residuos pecuarios | Residuos pecuarios: abono | `P602_4` | 42.7 % | 0.495 |
| 8 | `RA_COMBUST` | Activa | Residuos pecuarios | Residuos pecuarios: combustible | `P602_5` | 6.3 % | 0.243 |
| 9 | `RA_CAMPO` | Activa | Residuos pecuarios | Residuos pecuarios: deja en campo | `P602_6` | 37.7 % | 0.485 |
| 10 | `MINA` | Ilustrativa | Entorno e información | Minería cerca del predio | `P603 = 1` | 6.7 % | 0.251 |
| 11 | `INFO_EST` | Ilustrativa | Entorno e información | Informado por el Estado | `P604 = 1` | 6.8 % | 0.251 |
| 12 | `ALM_ADEC` | Ilustrativa | Almacenamiento | Almacén adecuado | `P606_1 | P606_3` | 43.6 % | 0.496 |
| 13 | `ALM_INADEC` | Ilustrativa | Almacenamiento | Almacén inadecuado | `P606_2 | P606_4` | 53.9 % | 0.498 |
| 14 | `CONOCE_ID` | Ilustrativa | Trazabilidad y calidad | Conoce identificación de alimentos | `P607 = 1` | 18.6 % | 0.389 |
| 15 | `CERTIF` | Ilustrativa | Trazabilidad y calidad | Certificación de calidad | `P608 = 1` | 0.6 % | 0.076 |

**Normalización.** Min–max: identidad para binarios (min = 0, max = 1). Puntuación z: `z = (x − media) / DE` (solo análisis de sensibilidad).

## C. Variables auxiliares en los archivos derivados

| Variable | Descripción |
|---|---|
| `ID` | Identificador secuencial reproducible `ENA<año>-<n>` |
| `DEPARTAMENTO` | Nombre normalizado desde `CCDD` (código de ubicación geográfica) |
| `REGION` | Región natural (Costa, Sierra, Selva) |
| `TAMANO` | Tamaño del productor (solo pequeño/mediano) |
| `CLUSTER` | 1 = C1 Aprovechamiento · 2 = C2 Baja valorización · 3 = C3 Abandono en campo |
