# ==================================================================
# 09_figures.R — Figuras del artículo
# ------------------------------------------------------------------
# Gráficos habituales en estudios de agrupamiento, con un estilo único
# (theme_paper) y la paleta de utils.R (azul marino, ámbar, verde azulado):
#   fig02  Prevalencia de las prácticas de residuos por región (barras)
#   fig03  Método del codo, silueta media y estabilidad según k
#   fig04  Dendrograma de Ward (patrones únicos ponderados)
#   fig05  Gráfico de silueta por clúster
#   fig06  Gráfico de clústeres en el plano de las dos primeras CP
#   fig07  Perfil de los clústeres (barras agrupadas)
#   fig08  Composición por región natural y evolución anual
# Exporta PDF vectorial (artículo) y PNG a 300 ppp (README).
# ==================================================================
source("R/utils.R")
suppressPackageStartupMessages({ library(patchwork); library(scales); library(cluster) })
cfg <- load_config()
set.seed(cfg$project$seed)
nm  <- unlist(cfg$cluster_names)
PAL <- setNames(PAL_CLUSTER[seq_along(nm)], nm)
FULL <- 7.16; HALF <- 3.5      # anchos IEEE (pulgadas): doble y simple columna

desc <- fread(file.path(cfg$paths$tables, "descriptivos_15var.csv"), encoding = "UTF-8")
sel  <- fread(file.path(cfg$paths$tables, "seleccion_k.csv"))
PR   <- readRDS(file.path(cfg$paths$models, "perfil.rds"))
CL   <- readRDS(file.path(cfg$paths$models, "clusters.rds"))
M    <- readRDS(file.path(cfg$paths$interim, "04_matrices.rds"))
short <- function(x) sub("^Residuos (de cultivo|pecuarios): ", "", x)
lab_cl <- VARS15[rol == "Agrupamiento"]
lab_cl[, corto := paste0(ifelse(bloque == "Residuos de cultivo", "Cultivo: ", "Pecuario: "),
                         short(etiqueta))]

# Fig. 2 — Prevalencia por región (barras agrupadas) ------------------------------
d2 <- melt(desc[var %in% lab_cl$var, c("var", REGIONES), with = FALSE],
           id.vars = "var", variable.name = "Region", value.name = "p")
d2[, et := factor(lab_cl$corto[match(var, lab_cl$var)], levels = rev(lab_cl$corto))]
p2 <- ggplot(d2, aes(p, et, fill = Region)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.72) +
  scale_fill_manual(values = PAL_REGION, name = NULL) +
  scale_x_continuous(labels = percent_format(accuracy = 1), expand = expansion(mult = c(0, .03))) +
  labs(x = "Productores (%)", y = NULL) + theme_paper() +
  theme(panel.grid.major.y = element_blank())
save_fig(p2, "fig02_prevalencia_region", cfg, width = HALF, height = 3.3)

# Fig. 3 — Codo, silueta y estabilidad ---------------------------------------------
kf <- sel[elegido == TRUE, k]
mk <- function(y, ttl, ylab) {
  ggplot(sel, aes(k, .data[[y]])) +
    geom_vline(xintercept = kf, linetype = 2, colour = INK2, linewidth = 0.4) +
    geom_line(colour = PAL_CLUSTER[1], linewidth = 0.7) +
    geom_point(colour = PAL_CLUSTER[1], size = 1.8) +
    geom_point(data = sel[k == kf], colour = PAL_CLUSTER[2], size = 2.8) +
    scale_x_continuous(breaks = sel$k) +
    labs(title = ttl, x = "Número de clústeres (k)", y = ylab) + theme_paper()
}
p3 <- (mk("wss", "(a) Método del codo", "WSS") +
         scale_y_continuous(labels = label_number(scale = 1e-3, suffix = " mil"))) |
  mk("sil_mean", "(b) Silueta media", "Ancho medio") |
  mk("ari_mean", "(c) Estabilidad bootstrap", "ARI medio")
save_fig(p3, "fig03_seleccion_k", cfg, width = FULL, height = 2.3)

# Fig. 4 — Dendrograma de Ward -----------------------------------------------------
hc <- CL$hc
dd <- as.dendrogram(hc)
seg <- function(node, x0 = 0) {   # coordenadas de segmentos (sin paquetes extra)
  out <- list()
  rec <- function(n) {
    if (is.leaf(n)) return(list(x = attr(n, "xpos"), h = 0))
    ch <- lapply(n, rec); h <- attr(n, "height")
    xs <- sapply(ch, `[[`, "x")
    for (c in ch) out[[length(out) + 1]] <<- c(c$x, c$h, c$x, h)
    out[[length(out) + 1]] <<- c(min(xs), h, max(xs), h)
    list(x = mean(range(xs)), h = h)
  }
  rec(node); do.call(rbind, out)
}
ord <- order.dendrogram(dd)
xpos <- integer(length(ord)); xpos[ord] <- seq_along(ord)
dd <- dendrapply(dd, function(n) { if (is.leaf(n)) attr(n, "xpos") <- xpos[n[1]]; n })
S <- as.data.table(seg(dd)); setnames(S, c("x", "y", "xend", "yend"))
cut_h <- mean(sort(hc$height, decreasing = TRUE)[CL$k - 1:0])
p4 <- ggplot(S) +
  geom_segment(aes(x, y, xend = xend, yend = yend), colour = PAL_CLUSTER[1], linewidth = 0.25) +
  geom_hline(yintercept = cut_h, colour = PAL_CLUSTER[2], linetype = 2, linewidth = 0.5) +
  annotate("text", x = length(ord) * 0.98, y = cut_h, label = paste0("corte k = ", CL$k),
           vjust = -0.5, hjust = 1, size = 2.5, colour = PAL_CLUSTER[2]) +
  scale_x_continuous(expand = c(0.01, 0)) +
  labs(x = sprintf("Patrones únicos de manejo (n = %d)", length(ord)),
       y = "Altura (Ward)") + theme_paper() +
  theme(axis.text.x = element_blank(), panel.grid.major.x = element_blank())
save_fig(p4, "fig04_dendrograma", cfg, width = HALF, height = 2.5)

# Fig. 5 — Gráfico de silueta --------------------------------------------------------
ix <- sample.int(length(CL$cl), 4000)
s <- silhouette(CL$cl[ix], dist(M$X_mm[ix, ]))
sd5 <- data.table(cluster = s[, 1], sil = s[, 3])
setorder(sd5, cluster, -sil); sd5[, pos := .I]
sd5[, CLUSTER := factor(nm[cluster], levels = nm)]
smean <- mean(sd5$sil)
p5 <- ggplot(sd5, aes(pos, sil, fill = CLUSTER)) +
  geom_col(width = 1) +
  geom_hline(yintercept = smean, linetype = 2, colour = INK2, linewidth = 0.4) +
  annotate("text", x = nrow(sd5), y = smean, label = sprintf("media = %.2f", smean),
           hjust = 1, vjust = -0.6, size = 2.4, colour = INK2) +
  scale_fill_manual(values = PAL, name = NULL) +
  guides(fill = guide_legend(nrow = 2, byrow = TRUE)) +
  labs(x = "Productores (submuestra de 4 000, ordenados)", y = "Ancho de silueta") +
  theme_paper() + theme(axis.text.x = element_blank(), panel.grid.major.x = element_blank())
save_fig(p5, "fig05_silueta", cfg, width = HALF, height = 2.5)

# Fig. 6 — Gráfico de clústeres (ACP) -------------------------------------------------
pi <- copy(PR$mca_ind)
jit <- function(x) x + runif(length(x), -0.06, 0.06)
pi[, `:=`(J1 = jit(Dim1), J2 = jit(Dim2))]
cent <- pi[, .(Dim1 = mean(Dim1), Dim2 = mean(Dim2)), by = CLUSTER]
p6 <- ggplot(pi, aes(J1, J2, colour = CLUSTER)) +
  geom_point(size = 0.5, alpha = 0.35) +
  stat_ellipse(aes(group = CLUSTER), level = 0.90, linewidth = 0.6) +
  geom_point(data = cent, aes(Dim1, Dim2, fill = CLUSTER), shape = 21, colour = "white",
             size = 3.4, stroke = 0.8) +
  scale_colour_manual(values = PAL, name = NULL) +
  scale_fill_manual(values = PAL, guide = "none") +
  guides(colour = guide_legend(nrow = 2, byrow = TRUE, override.aes = list(size = 2.5, alpha = 1, linetype = 0))) +
  labs(x = sprintf("CP1 (%.1f %%)", PR$mca_eig[1]), y = sprintf("CP2 (%.1f %%)", PR$mca_eig[2])) +
  theme_paper()
save_fig(p6, "fig06_clusters_acp", cfg, width = HALF, height = 3.0)

# Fig. 7 — Perfil de los clústeres ------------------------------------------------------
d7 <- PR$prof_long[rol == "Agrupamiento"]
d7[, et := factor(lab_cl$corto[match(var, lab_cl$var)], levels = rev(lab_cl$corto))]
d7[, CLUSTER := factor(CLUSTER, levels = rev(nm))]
p7 <- ggplot(d7, aes(prev, et, fill = CLUSTER)) +
  geom_col(position = position_dodge(width = 0.82), width = 0.76) +
  scale_fill_manual(values = PAL, breaks = nm, name = NULL) +
  scale_x_continuous(labels = percent_format(accuracy = 1), limits = c(0, 1),
                     expand = expansion(mult = c(0, .02))) +
  guides(fill = guide_legend(nrow = 2, byrow = TRUE)) +
  labs(x = "Productores del grupo (%)", y = NULL) +
  theme_paper() + theme(panel.grid.major.y = element_blank(),
                        legend.position = "top", legend.justification = "right",
                        legend.text = element_text(size = 6.5))
save_fig(p7, "fig07_perfil_clusters", cfg, width = HALF, height = 3.7)

# Fig. 8 — Región natural y evolución anual ----------------------------------------------
cr <- copy(PR$comp_reg); cr[, CLUSTER := factor(CLUSTER, levels = rev(nm))]
p8a <- ggplot(cr, aes(pct, REGION_LAB, fill = CLUSTER)) +
  geom_col(width = 0.65) +
  geom_text(aes(label = sprintf("%.0f %%", pct)), position = position_stack(vjust = .5),
            size = 2.4, colour = "white") +
  scale_fill_manual(values = PAL, breaks = nm, name = NULL) +
  scale_x_continuous(labels = function(x) paste0(x, " %"), expand = c(0, 0)) +
  labs(x = "Productores de la región (%)", y = NULL, title = "(a) Por región natural") +
  theme_paper() + theme(panel.grid.major.y = element_blank())
ca <- copy(PR$comp_anio); ca[, CLUSTER := factor(CLUSTER, levels = nm)]
p8b <- ggplot(ca, aes(factor(ANIO), pct, colour = CLUSTER, group = CLUSTER)) +
  geom_line(linewidth = 0.7) + geom_point(size = 1.5) +
  scale_colour_manual(values = PAL, guide = "none") +
  scale_y_continuous(labels = function(x) paste0(x, " %"), limits = c(0, NA)) +
  labs(x = "Año de la encuesta (sin datos en 2020–2021)", y = "Productores (%)",
       title = "(b) Por año") + theme_paper()
p8 <- (p8a | p8b) + plot_layout(widths = c(1, 1.2), guides = "collect") &
  theme(legend.position = "bottom")
save_fig(p8, "fig08_region_anio", cfg, width = FULL, height = 2.5)

# Limpia figuras de versiones anteriores que ya no se usan
old <- c("fig04_perfiles_heatmap", "fig05_acm", "fig06_region_tiempo",
         "fig07_departamentos", "fig08_validacion")
for (d in c(cfg$paths$figures, cfg$paths$paper_figures))
  unlink(file.path(d, c(paste0(old, ".pdf"), paste0(old, ".png"))))
log_msg("Figuras generadas en ", cfg$paths$figures, cfg = cfg)
