# ==================================================================
# 08_profile.R — Perfilamiento e interpretación de los clústeres
# ------------------------------------------------------------------
# * Centroides = prevalencias de cada indicador por clúster.
# * Asociación con covariables externas (no usadas en el agrupamiento):
#   región natural, tamaño del productor, año y departamento
#   (chi-cuadrado de Pearson y V de Cramér).
# * Análisis de componentes principales (ACP) para el gráfico de clústeres.
# Salida: outputs/tables/perfil_*.csv, outputs/models/perfil.rds
# ==================================================================
source("R/utils.R")
cfg <- load_config()
set.seed(cfg$project$seed)
feat <- readRDS(file.path(cfg$paths$interim, "03_features.rds"))
CL   <- readRDS(file.path(cfg$paths$models, "clusters.rds"))
v <- VARS15$var
nm <- unlist(cfg$cluster_names)
feat[, CLUSTER := factor(nm[as.character(CL$cl)], levels = nm)]

# Centroides / prevalencias ------------------------------------------------
prof <- feat[, lapply(.SD, mean), by = CLUSTER, .SDcols = v][order(CLUSTER)]
prof_long <- melt(prof, id.vars = "CLUSTER", variable.name = "var", value.name = "prev")
prof_long <- merge(prof_long, VARS15[, .(var, etiqueta, bloque, rol)], by = "var")
glob <- data.table(var = v, prev_global = sapply(v, function(x) mean(feat[[x]])))
prof_long <- merge(prof_long, glob, by = "var")
prof_long[, dif_pp := 100 * (prev - prev_global)]
fwrite(prof_long, file.path(cfg$paths$tables, "perfil_centroides.csv"))

# Asociación con covariables externas --------------------------------------
cramer <- function(tab) {
  ch <- suppressWarnings(chisq.test(tab, correct = FALSE))
  data.table(chi2 = unname(ch$statistic), gl = unname(ch$parameter),
             p = ch$p.value,
             V = sqrt(unname(ch$statistic) / (sum(tab) * (min(dim(tab)) - 1))))
}
assoc <- rbindlist(list(
  cbind(covariable = "Región natural", cramer(table(feat$CLUSTER, feat$REGION_LAB))),
  cbind(covariable = "Año", cramer(table(feat$CLUSTER, feat$ANIO))),
  cbind(covariable = "Departamento", cramer(table(feat$CLUSTER, feat$DEPARTAMENTO)))
))
fwrite(assoc, file.path(cfg$paths$tables, "perfil_asociacion.csv"))

comp_reg  <- feat[, .N, by = .(REGION_LAB, CLUSTER)][, pct := 100 * N / sum(N), by = REGION_LAB]
comp_tam  <- feat[, .N, by = .(TAMANO_LAB, CLUSTER)][, pct := 100 * N / sum(N), by = TAMANO_LAB]
comp_anio <- feat[, .N, by = .(ANIO, CLUSTER)][, pct := 100 * N / sum(N), by = ANIO]
comp_dep  <- feat[, .N, by = .(DEPARTAMENTO, CLUSTER)][
  , pct := 100 * N / sum(N), by = DEPARTAMENTO]
# Región dominante del departamento (para ordenar la figura)
dep_reg <- feat[, .N, by = .(DEPARTAMENTO, REGION_LAB)][order(-N)][, .SD[1], by = DEPARTAMENTO]
fwrite(comp_reg,  file.path(cfg$paths$tables, "perfil_region.csv"))
fwrite(comp_tam,  file.path(cfg$paths$tables, "perfil_tamano.csv"))
fwrite(comp_anio, file.path(cfg$paths$tables, "perfil_anio.csv"))
fwrite(comp_dep,  file.path(cfg$paths$tables, "perfil_departamento.csv"))

# Tendencia temporal: pendiente lineal (pp/año) de la participación de cada clúster
trend <- comp_anio[, {
  f <- lm(pct ~ ANIO); s <- summary(f)$coefficients
  .(pendiente_pp_anio = s[2, 1], ee = s[2, 2], p = s[2, 4])
}, by = CLUSTER]
fwrite(trend, file.path(cfg$paths$tables, "perfil_tendencia.csv"))

# ACP sobre las 9 variables de residuos (solo para el gráfico de clústeres)
M <- readRDS(file.path(cfg$paths$interim, "04_matrices.rds"))
pca <- prcomp(M$X_mm, center = TRUE, scale. = FALSE)
eig <- 100 * pca$sdev^2 / sum(pca$sdev^2)
idx <- feat[, .I[sample(.N, min(.N, 3000))], by = CLUSTER]$V1
pca_ind <- data.table(pca$x[idx, 1:2], CLUSTER = feat$CLUSTER[idx])
setnames(pca_ind, 1:2, c("Dim1", "Dim2"))
pca_var <- data.table(var = rownames(pca$rotation), pca$rotation[, 1:2])
mca_ind <- pca_ind; mca_var <- pca_var; eig <- eig[1:2]

saveRDS(list(feat_cluster = feat[, .(ID, CLUSTER)], prof_long = prof_long,
             comp_reg = comp_reg, comp_tam = comp_tam, comp_anio = comp_anio,
             comp_dep = comp_dep, dep_reg = dep_reg, assoc = assoc, trend = trend,
             mca_ind = mca_ind, mca_var = mca_var, mca_eig = eig),
        file.path(cfg$paths$models, "perfil.rds"))
# Tabla de asignaciones (dato derivado publicable en Zenodo)
fwrite(cbind(feat[, .(ID, ANIO, DEPARTAMENTO, REGION = REGION_LAB, TAMANO = TAMANO_LAB)],
             feat[, ..v], CLUSTER = as.integer(CL$cl)),
       file.path(cfg$paths$interim, "ena_cap600_clusters.csv.gz"))
log_msg("Perfilamiento completado. V de Cramér (región) = ",
        round(assoc[covariable == "Región natural", V], 3), cfg = cfg)
