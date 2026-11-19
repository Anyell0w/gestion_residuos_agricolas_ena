# ==================================================================
# 02_clean.R — Depuración, armonización y control de calidad
# ------------------------------------------------------------------
# Reglas (documentadas en el artículo, Sección III-B):
#  R1. Solo encuestas completas (RESFIN = 1).
#  R2. Se excluyen unidades con el Capítulo 600 omitido (P601_* faltante).
#  R3. Códigos 9 (no especificado) en P607/P608 -> NA y exclusión.
#  R4. REGION = 4 (Lima Metropolitana, solo 2017, no documentado) -> Costa.
#  R5. Nombre de departamento reconstruido desde CCDD (UBIGEO), corrigiendo
#      nombres vacíos y variantes ortográficas (p. ej., APURIMAC/APURÍMAC).
#  R6. Se excluyen 2014–2015: las opciones de respuesta de P601/P602 cambian
#      y no son comparables con 2016–2025 (verificado con prevalencias anuales).
#  R7. P607 faltante cuando P606_* = 0 es un salto estructural del
#      cuestionario (no conserva alimentos) y NO un valor perdido.
# Salida: data/processed/02_clean.rds, outputs/tables/flujo_depuracion.csv
# ==================================================================
source("R/utils.R")
cfg <- load_config()
d <- readRDS(file.path(cfg$paths$interim, "01_ingest.rds"))
flow <- data.table(paso = "Registros crudos", n = nrow(d))
add <- function(lbl, dt) flow <<- rbind(flow, data.table(paso = lbl, n = nrow(dt)))

# R1
d <- d[RESFIN %in% cfg$clean$keep_resfin]; add("R1: encuesta completa", d)
# R2
d <- d[!is.na(P601_1) & !is.na(P602_1) & !is.na(P603) & !is.na(P604) &
         !is.na(P606_1) & !is.na(P608)]
add("R2: Cap. 600 respondido", d)
# R3
d[P607 == 9, P607 := NA_integer_]
d[P608 == 9, P608 := NA_integer_]
d <- d[!is.na(P608) & !(is.na(P607) & (P606_1 + P606_2 + P606_3 + P606_4 + P606_5) > 0)]
add("R3: sin código 9", d)
# R6 (armonización temporal del cuestionario)
anual <- d[, .(P601_5 = mean(P601_5), P602_6 = mean(P602_6), P602_7 = mean(P602_7)), by = ANIO]
fwrite(anual[order(ANIO)], file.path(cfg$paths$tables, "armonizacion_anual.csv"))
d <- d[!ANIO %in% unlist(cfg$clean$years_exclude)]
add("R6: ediciones 2016–2025", d)
# R4
for (from in names(cfg$clean$region_recode)) {
  d[REGION == as.integer(from), REGION := as.integer(cfg$clean$region_recode[[from]])]
}
stopifnot(all(d$REGION %in% 1:3))
# R5
d <- merge(d, DEPARTAMENTOS, by = "CCDD", all.x = TRUE, sort = FALSE)
stopifnot(!anyNA(d$DEPARTAMENTO))
# Identificador secuencial reproducible. Nota: ANIO+UBIGEO+UA no es una llave
# única en la ENA (faltan conglomerado/segmento en el extracto), por lo que no
# se deduplica por esa combinación; se reporta su multiplicidad como auditoría.
setorder(d, ANIO, CCDD, CCPP, CCDI, UA)
d[, ID := sprintf("ENA%d-%06d", ANIO, seq_len(.N)), by = ANIO]
mult <- d[, .N, by = .(ANIO, CCDD, CCPP, CCDI, UA)][, mean(N > 1)]
log_msg("Proporción de llaves ANIO+UBIGEO+UA repetidas: ", round(mult, 3), cfg = cfg)
stopifnot(!anyDuplicated(d$ID))

flow[, retenido_pct := round(100 * n / n[1], 2)]
fwrite(flow, file.path(cfg$paths$tables, "flujo_depuracion.csv"))
saveRDS(d, file.path(cfg$paths$interim, "02_clean.rds"), compress = "xz")
log_msg("Depuración: ", nrow(d), " registros válidos (",
        flow[.N, retenido_pct], "% del total)", cfg = cfg)
