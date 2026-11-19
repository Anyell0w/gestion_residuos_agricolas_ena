# ==================================================================
# 05_select_k.R — Selección del número de clústeres k
# ------------------------------------------------------------------
# Para k en k_grid se ajusta k-means ponderado sobre los patrones únicos de las
# 9 variables de residuos (equivalente exacto a k-means sobre los n registros,
# con `kmeans_nstart` inicios k-means++) y se calculan:
#   * WSS (codo), Calinski–Harabasz (CH, máx.) y Davies–Bouldin (DB, mín.)
#     sobre los n registros;
#   * silueta media (máx.) por submuestreo repetido;
#   * estadístico gap (Tibshirani et al.) en una submuestra, regla 1-SE;
#   * estabilidad bootstrap (ARI medio).
# Regla preespecificada (config.yml): entre los k con ARI >= min_ari y clúster
# mínimo >= min_pct, se elige el que minimiza DB.
# Salida: outputs/tables/seleccion_k.csv, outputs/models/kmeans_grid.rds
# ==================================================================
source("R/utils.R")
suppressPackageStartupMessages({ library(cluster); library(mclust) })
cfg <- load_config()
set.seed(cfg$project$seed)
M <- readRDS(file.path(cfg$paths$interim, "04_matrices.rds"))
X <- M$X_mm; P <- M$P; w <- M$freq; pidx <- M$pat_idx
cc <- cfg$clustering
n <- nrow(X)

sub_idx <- replicate(cc$silhouette_reps, sample.int(n, cc$silhouette_subsample),
                     simplify = FALSE)
D_sub <- lapply(sub_idx, function(ix) dist(X[ix, ]))

fits <- list(); res <- list()
for (k in cc$k_grid) {
  t0 <- Sys.time()
  fit <- wkmeans(P, w, k, nstart = cc$kmeans_nstart)
  # Refinamiento final con Hartigan–Wong sobre los n registros, partiendo
  # del mejor centroide encontrado (garantiza un óptimo local de HW).
  hw <- suppressWarnings(kmeans(X, centers = fit$centers, iter.max = cc$kmeans_iter_max,
                                algorithm = "Hartigan-Wong"))
  hw2 <- suppressWarnings(kmeans(X, centers = k, nstart = 10,
                                 iter.max = cc$kmeans_iter_max))   # inicios aleatorios HW
  if (hw2$tot.withinss < hw$tot.withinss) hw <- hw2
  if (hw$tot.withinss < fit$wss - 1e-6) {
    fit$centers <- hw$centers; fit$wss <- hw$tot.withinss
    fit$cluster <- assign_nearest(P, hw$centers); fit$size <- hw$size
  }
  cl <- fit$cluster[pidx]
  fit$cluster_rows <- cl
  fits[[as.character(k)]] <- fit
  sil <- mapply(function(ix, D) mean(silhouette(cl[ix], D)[, 3]), sub_idx, D_sub)
  boot <- wkmeans_stability(P, w, pidx, cl, k, reps = cc$stability_reps_k)
  ari <- sapply(boot, adjustedRandIndex, cl)
  res[[as.character(k)]] <- data.table(
    k = k, wss = fit$wss, ch = ch_index(X, cl), db = db_index(X, cl),
    sil_mean = mean(sil), sil_sd = sd(sil),
    ari_mean = mean(ari), ari_sd = sd(ari),
    min_cluster_pct = 100 * min(fit$size) / n)
  r <- res[[as.character(k)]]
  log_msg(sprintf("  k=%d  WSS=%.0f  CH=%.0f  DB=%.3f  Sil=%.3f  ARI=%.3f (%.1fs)", k,
                  r$wss, r$ch, r$db, r$sil_mean, r$ari_mean,
                  as.numeric(difftime(Sys.time(), t0, units = "secs"))), cfg = cfg)
}
sel <- rbindlist(res)

# Estadístico gap en submuestra (B referencias uniformes)
gap_idx <- sample.int(n, 4000)
gs <- clusGap(X[gap_idx, ], FUNcluster = function(x, k) kmeans(x, k, nstart = 10, iter.max = 50),
              K.max = max(cc$k_grid), B = 30, verbose = FALSE)
gt <- as.data.table(gs$Tab)[, k := .I]
sel <- merge(sel, gt[, .(k, gap, gap_se = SE.sim)], by = "k")
k_gap <- maxSE(gs$Tab[, "gap"], gs$Tab[, "SE.sim"], method = "Tibs2001SEmax")

votes <- c(sil = sel[which.max(sil_mean), k], ch = sel[which.max(ch), k],
           db = sel[which.min(db), k], gap = k_gap,
           estabilidad = sel[which.max(ari_mean), k])
ok <- sel[ari_mean >= cc$k_rule$min_ari & min_cluster_pct >= cc$k_rule$min_pct]
k_final <- if (nrow(ok)) ok[which.min(db), k] else sel[which.max(ari_mean), k]
sel[, elegido := k == k_final]

fwrite(sel, file.path(cfg$paths$tables, "seleccion_k.csv"))
fwrite(data.table(criterio = names(votes), k = votes),
       file.path(cfg$paths$tables, "votos_k.csv"))
saveRDS(list(fits = fits, gap = gs, votes = votes, k_final = k_final),
        file.path(cfg$paths$models, "kmeans_grid.rds"))
log_msg("k final = ", k_final, " | votos: ",
        paste(names(votes), votes, sep = "=", collapse = ", "), cfg = cfg)
