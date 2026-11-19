# ==================================================================
# 07_validate.R — Validación interna y estabilidad de la solución final
# ------------------------------------------------------------------
# * Silueta por clúster (submuestreo repetido).
# * Estabilidad global: ARI bootstrap (B = bootstrap_reps).
# * Estabilidad por clúster: índice de Jaccard máximo entre el clúster de
#   referencia y los clústeres de cada réplica (Hennig, 2007).
# Salida: outputs/tables/validacion_*.csv, outputs/models/validacion.rds
# ==================================================================
source("R/utils.R")
suppressPackageStartupMessages({ library(cluster); library(mclust) })
cfg <- load_config()
set.seed(cfg$project$seed + 1)
M  <- readRDS(file.path(cfg$paths$interim, "04_matrices.rds"))
CL <- readRDS(file.path(cfg$paths$models, "clusters.rds"))
cc <- cfg$clustering
X <- M$X_mm; cl <- CL$cl; k <- CL$k; n <- nrow(X)

# Silueta por clúster ---------------------------------------------------
sil_rows <- rbindlist(lapply(seq_len(cc$silhouette_reps), function(r) {
  ix <- sample.int(n, cc$silhouette_subsample)
  s <- silhouette(cl[ix], dist(X[ix, ]))
  data.table(rep = r, cluster = s[, 1], sil = s[, 3])
}))
sil_tab <- sil_rows[, .(sil_media = mean(sil), sil_neg_pct = 100 * mean(sil < 0)),
                    by = cluster][order(cluster)]

# Estabilidad bootstrap (multinomial exacta sobre patrones) ---------------
P <- M$P; w <- M$freq; pidx <- M$pat_idx
labs <- wkmeans_stability(P, w, pidx, cl, k, reps = cc$bootstrap_reps)
boot <- rbindlist(lapply(seq_along(labs), function(b) {
  pb <- labs[[b]]
  jac <- sapply(seq_len(k), function(g) {
    a <- cl == g
    max(sapply(seq_len(k), function(h) { bb <- pb == h; sum(a & bb) / sum(a | bb) }))
  })
  data.table(rep = b, ari = adjustedRandIndex(pb, cl), cluster = seq_len(k), jaccard = jac)
}))
stab_global <- boot[, .(ari = ari[1]), by = rep][, .(ari_media = mean(ari), ari_sd = sd(ari),
                                                      ari_p05 = quantile(ari, .05))]
stab_cl <- boot[, .(jaccard_media = mean(jaccard), jaccard_p05 = quantile(jaccard, .05)),
                by = cluster][order(cluster)]

val <- merge(sil_tab, stab_cl, by = "cluster")
val[, n := as.vector(table(cl))][, pct := round(100 * n / sum(n), 2)]
fwrite(val, file.path(cfg$paths$tables, "validacion_por_cluster.csv"))
fwrite(stab_global, file.path(cfg$paths$tables, "validacion_global.csv"))
saveRDS(list(sil = sil_rows, boot = boot), file.path(cfg$paths$models, "validacion.rds"))
log_msg(sprintf("Validación: ARI bootstrap = %.3f (DE %.3f); Jaccard por clúster = %s",
                stab_global$ari_media, stab_global$ari_sd,
                paste(round(stab_cl$jaccard_media, 3), collapse = "/")), cfg = cfg)
