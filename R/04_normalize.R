# ==================================================================
# 04_normalize.R — Normalización y compresión por patrones únicos
# ------------------------------------------------------------------
# Se normalizan las 9 variables de gestión de residuos usadas para agrupar.
# (a) Min–max [0,1]: para indicadores binarios es la identidad; la distancia
#     euclidiana al cuadrado equivale a la distancia de Hamming (nº de
#     discrepancias), lo que hace interpretables los centroides como
#     prevalencias. ESPECIFICACIÓN PRINCIPAL.
# (b) Puntuación z: z = (x - media)/de. ANÁLISIS DE SENSIBILIDAD
#     (pondera más los atributos raros).
# (c) Compresión: los n registros se reducen a P patrones binarios únicos
#     con su frecuencia, base de los métodos de costo O(P^2) (Ward).
# Salidas: data/processed/04_matrices.rds, outputs/tables/normalizacion.csv
# ==================================================================
source("R/utils.R")
cfg <- load_config()
feat <- readRDS(file.path(cfg$paths$interim, "03_features.rds"))
v <- VARS_CL                      # solo las 9 variables de residuos

X_raw <- as.matrix(feat[, ..v]) * 1.0
mins <- apply(X_raw, 2, min); maxs <- apply(X_raw, 2, max)
X_mm <- sweep(sweep(X_raw, 2, mins), 2, pmax(maxs - mins, 1e-12), "/")
mu <- colMeans(X_raw); s <- apply(X_raw, 2, sd)
X_z <- scale(X_raw, center = mu, scale = s)
attr(X_z, "scaled:center") <- NULL; attr(X_z, "scaled:scale") <- NULL

norm_tab <- data.table(var = v, min = mins, max = maxs, media = mu, de = s,
                       z_si_0 = -mu / s, z_si_1 = (1 - mu) / s)
fwrite(norm_tab, file.path(cfg$paths$tables, "normalizacion.csv"))

# Compresión por patrones únicos
key <- apply(X_raw, 1, paste, collapse = "")
pat <- data.table(pkey = key)[, .(freq = .N), by = "pkey"]
setorder(pat, -freq)
P <- do.call(rbind, lapply(strsplit(pat$pkey, ""), as.integer)) * 1.0
colnames(P) <- v
pat_idx <- match(key, pat$pkey)

saveRDS(list(X_mm = X_mm, X_z = X_z, P = P, freq = pat$freq, pat_idx = pat_idx,
             norm = norm_tab),
        file.path(cfg$paths$interim, "04_matrices.rds"))
comp <- data.table(registros = nrow(X_raw), patrones_unicos = nrow(P),
                   tasa_compresion = round(nrow(X_raw) / nrow(P), 1),
                   cobertura_top20 = round(sum(head(pat$freq, 20)) / nrow(X_raw), 4))
fwrite(comp, file.path(cfg$paths$tables, "compresion_patrones.csv"))
log_msg("Normalización OK; ", nrow(X_raw), " registros -> ", nrow(P),
        " patrones únicos", cfg = cfg)
