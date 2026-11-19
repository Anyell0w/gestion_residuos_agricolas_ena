# ==================================================================
# 03_features.R — Construcción de las 15 variables analíticas
# ------------------------------------------------------------------
# Cada variable es un indicador binario (0/1) derivado de una o más
# preguntas del Capítulo 600 (ver VARS15 en utils.R y Tabla I del artículo).
# Salida: data/processed/03_features.rds, outputs/tables/descriptivos_15var.csv
# ==================================================================
source("R/utils.R")
cfg <- load_config()
d <- readRDS(file.path(cfg$paths$interim, "02_clean.rds"))

b <- function(x) as.integer(x == 1L)
d[, `:=`(
  RC_QUEMA    = b(P601_1),
  RC_ALIMENTO = b(P601_2),
  RC_BOTA     = b(P601_3),
  RC_ABONO    = b(P601_4),
  RC_CAMPO    = b(P601_5),
  RA_INADEC   = as.integer(P602_1 == 1L | P602_2 == 1L | P602_3 == 1L),
  RA_ABONO    = b(P602_4),
  RA_COMBUST  = b(P602_5),
  RA_CAMPO    = b(P602_6),
  MINA        = b(P603),
  INFO_EST    = b(P604),
  ALM_ADEC    = as.integer(P606_1 == 1L | P606_3 == 1L),
  ALM_INADEC  = as.integer(P606_2 == 1L | P606_4 == 1L),
  CONOCE_ID   = as.integer(!is.na(P607) & P607 == 1L),   # salto estructural -> 0
  CERTIF      = b(P608)
)]
v <- VARS15$var
stopifnot(!anyNA(d[, ..v]))
d[, REGION_LAB := factor(REGIONES[as.character(REGION)], levels = REGIONES)]
d[, TAMANO_LAB := factor(TAMANO[as.character(CODIGO)], levels = TAMANO)]

feat <- d[, c("ID", "ANIO", "CCDD", "DEPARTAMENTO", "REGION", "REGION_LAB",
              "CODIGO", "TAMANO_LAB", v), with = FALSE]

# Estadísticos descriptivos: prevalencia global y por región natural
desc <- VARS15[, .(var, etiqueta, origen, bloque)]
desc[, global := sapply(var, function(x) mean(feat[[x]]))]
for (r in REGIONES) {
  desc[, (r) := sapply(var, function(x) mean(feat[REGION_LAB == r][[x]]))]
}
desc[, sd := sapply(var, function(x) sd(feat[[x]]))]
fwrite(desc, file.path(cfg$paths$tables, "descriptivos_15var.csv"))

saveRDS(feat, file.path(cfg$paths$interim, "03_features.rds"), compress = "xz")
fwrite(feat, file.path(cfg$paths$interim, "ena_cap600_15var.csv.gz"))
log_msg("Variables construidas: ", length(v), " indicadores; n = ", nrow(feat), cfg = cfg)
