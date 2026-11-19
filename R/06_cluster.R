# ==================================================================
# 06_cluster.R — Agrupamiento final y métodos de contraste
# ------------------------------------------------------------------
# M1  k-means (principal): óptimo de 05_select_k.R (k-means ponderado sobre
#     patrones + refinamiento Hartigan–Wong), matriz min–max, k = k_final.
# M2  Ward jerárquico EXACTO sobre los P patrones únicos con pesos
#     (hclust(..., members = freq)); equivale a Ward sobre los n registros,
#     porque registros idénticos tienen distancia nula y se fusionan primero.
# M3  CLARA (k-medoides por muestreo) con distancia de Manhattan (= Hamming).
# M4  k-means sobre puntuaciones z (sensibilidad a la normalización).
# Concordancia entre métodos: índice de Rand ajustado (ARI).
# Salida: outputs/models/clusters.rds, outputs/tables/concordancia_ari.csv
# ==================================================================
source("R/utils.R")
suppressPackageStartupMessages({ library(cluster); library(mclust) })
cfg <- load_config()
set.seed(cfg$project$seed)
M <- readRDS(file.path(cfg$paths$interim, "04_matrices.rds"))
G <- readRDS(file.path(cfg$paths$models, "kmeans_grid.rds"))
cc <- cfg$clustering
k <- G$k_final
X <- M$X_mm

# M1 -----------------------------------------------------------------
km <- G$fits[[as.character(k)]]
cl_km <- relabel_by_size(km$cluster_rows)
centers <- rowsum(X, cl_km) / as.vector(table(cl_km))

# M2 -----------------------------------------------------------------
hc <- hclust(dist(M$P), method = "ward.D2", members = M$freq)
cl_ward <- cutree(hc, k = k)[M$pat_idx]

# M3 -----------------------------------------------------------------
cla <- clara(X, k = k, metric = "manhattan", samples = cc$clara_samples,
             sampsize = cc$clara_sampsize, pamLike = TRUE, rngR = TRUE)
cl_clara <- cla$clustering

# M4 -----------------------------------------------------------------
kz <- kmeans(M$X_z, centers = k, nstart = cc$kmeans_nstart, iter.max = cc$kmeans_iter_max)
cl_z <- kz$cluster

L <- list(`k-means` = cl_km, `Ward` = cl_ward, `CLARA` = cl_clara,
          `k-means (z)` = cl_z)
ari <- outer(names(L), names(L), Vectorize(function(a, b)
  adjustedRandIndex(L[[a]], L[[b]])))
dimnames(ari) <- list(names(L), names(L))
fwrite(as.data.table(ari, keep.rownames = "metodo"),
       file.path(cfg$paths$tables, "concordancia_ari.csv"))

saveRDS(list(k = k, cl = cl_km, centers = centers, labels = L, hc = hc,
             clara_medoids = cla$medoids),
        file.path(cfg$paths$models, "clusters.rds"))
log_msg("Agrupamiento final k=", k, "; tamaños: ",
        paste(tabulate(cl_km), collapse = "/"), "; ARI k-means vs Ward/CLARA/z = ",
        paste(round(ari[1, -1], 3), collapse = "/"), cfg = cfg)
