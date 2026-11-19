# ==================================================================
invisible(suppressWarnings(Sys.setlocale("LC_ALL", "C.UTF-8")))
# utils.R — Funciones auxiliares compartidas por todo el pipeline
# ==================================================================
suppressPackageStartupMessages({
  library(data.table)
  library(yaml)
  library(ggplot2)
})

# ---- Configuración ------------------------------------------------
load_config <- function(path = "config/config.yml") {
  cfg <- yaml::read_yaml(path, fileEncoding = "UTF-8")
  for (p in cfg$paths[c("interim", "figures", "tables", "models", "logs",
                         "paper_figures", "paper_tables")]) {
    dir.create(p, showWarnings = FALSE, recursive = TRUE)
  }
  cfg
}

# ---- Registro (log) -----------------------------------------------
log_msg <- function(..., cfg = NULL) {
  msg <- sprintf("[%s] %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
                 paste0(..., collapse = ""))
  message(msg)
  logdir <- if (!is.null(cfg)) cfg$paths$logs else "logs"
  dir.create(logdir, showWarnings = FALSE, recursive = TRUE)
  cat(msg, "\n", file = file.path(logdir, "pipeline.log"), append = TRUE)
  invisible(msg)
}

# ---- Catálogo de departamentos (código UBIGEO INEI) -----------------
# Corrige nombres vacíos y variantes con/sin tilde usando el código CCDD.
DEPARTAMENTOS <- data.table(
  CCDD = 1:25,
  DEPARTAMENTO = c("Amazonas", "Áncash", "Apurímac", "Arequipa", "Ayacucho",
                   "Cajamarca", "Callao", "Cusco", "Huancavelica", "Huánuco",
                   "Ica", "Junín", "La Libertad", "Lambayeque", "Lima",
                   "Loreto", "Madre de Dios", "Moquegua", "Pasco", "Piura",
                   "Puno", "San Martín", "Tacna", "Tumbes", "Ucayali")
)

REGIONES <- c("1" = "Costa", "2" = "Sierra", "3" = "Selva")
TAMANO   <- c("1" = "Pequeño/mediano", "2" = "Grande")

# ---- Las 15 variables analíticas ---------------------------------
# Nombre corto, etiqueta en español y bloque temático.
VARS15 <- data.table(
  var = c("RC_QUEMA", "RC_ALIMENTO", "RC_BOTA", "RC_ABONO", "RC_CAMPO",
          "RA_INADEC", "RA_ABONO", "RA_COMBUST", "RA_CAMPO",
          "MINA", "INFO_EST",
          "ALM_ADEC", "ALM_INADEC",
          "CONOCE_ID", "CERTIF"),
  etiqueta = c("Residuos de cultivo: quema",
               "Residuos de cultivo: alimento animal",
               "Residuos de cultivo: bota",
               "Residuos de cultivo: abono",
               "Residuos de cultivo: deja en campo",
               "Residuos pecuarios: quema/entierra/bota",
               "Residuos pecuarios: abono",
               "Residuos pecuarios: combustible",
               "Residuos pecuarios: deja en campo",
               "Minería cerca del predio",
               "Informado por el Estado",
               "Almacén adecuado",
               "Almacén inadecuado",
               "Conoce identificación de alimentos",
               "Certificación de calidad"),
  origen = c("P601_1", "P601_2", "P601_3", "P601_4", "P601_5",
             "P602_1 | P602_2 | P602_3", "P602_4", "P602_5", "P602_6",
             "P603 = 1", "P604 = 1",
             "P606_1 | P606_3", "P606_2 | P606_4",
             "P607 = 1", "P608 = 1"),
  bloque = c(rep("Residuos de cultivo", 5), rep("Residuos pecuarios", 4),
             rep("Entorno e información", 2), rep("Almacenamiento", 2),
             rep("Trazabilidad y calidad", 2)),
  # Rol en el análisis: las 9 variables de residuos definen los grupos;
  # las 6 restantes solo los describen (variables ilustrativas).
  rol = c(rep("Agrupamiento", 9), rep("Perfil", 6))
)
VARS_CL <- VARS15[rol == "Agrupamiento", var]

# ---- Paleta y tema gráfico consistentes ---------------------------
# Paleta categórica validada (orden fijo, nunca cíclico).
# Paleta inspirada en el estilo editorial de Wiley (azul marino, ámbar, verde azulado)
PAL_CLUSTER <- c("#1F4E79", "#D9822B", "#2A9D8F", "#8E6C8A",
                 "#C0504D", "#6B8E23", "#4F81BD", "#7F7F7F")
PAL_REGION  <- c(Costa = "#4F81BD", Sierra = "#B5835A", Selva = "#5B9A68")
SEQ_LOW  <- "#EEF3F8"   # rampa secuencial azul (claro -> oscuro)
SEQ_HIGH <- "#1F4E79"
INK      <- "#0b0b0b"
INK2     <- "#52514e"
GRID     <- "#e6e5e0"

theme_paper <- function(base_size = 9) {
  theme_minimal(base_size = base_size, base_family = "sans") +
    theme(
      text             = element_text(colour = INK),
      axis.text        = element_text(colour = INK2),
      axis.title       = element_text(colour = INK2),
      panel.grid.major = element_line(colour = GRID, linewidth = 0.3),
      panel.grid.minor = element_blank(),
      plot.title       = element_text(face = "bold", size = base_size + 1),
      plot.subtitle    = element_text(colour = INK2),
      legend.position  = "bottom",
      legend.title     = element_text(colour = INK2),
      strip.text       = element_text(face = "bold", colour = INK),
      legend.text      = element_text(size = base_size - 1.5),
      legend.key.size  = unit(0.3, "cm"),
      legend.margin    = margin(0, 0, 0, 0),
      plot.margin      = margin(4, 10, 4, 4)
    )
}

save_fig <- function(p, name, cfg, width = 3.5, height = 2.6) {
  for (dir in c(cfg$paths$figures, cfg$paths$paper_figures)) {
    ggsave(file.path(dir, paste0(name, ".pdf")), p, width = width,
           height = height, device = cairo_pdf)
  }
  ggsave(file.path(cfg$paths$figures, paste0(name, ".png")), p,
         width = width, height = height, dpi = 300, bg = "white")
  invisible(p)
}

# ---- Índices de validación interna ---------------------------------
# Calinski–Harabasz y Davies–Bouldin calculados en O(nk) (aptos para n grande).
ch_index <- function(X, cl) {
  n <- nrow(X); k <- length(unique(cl))
  mu <- colMeans(X)
  cent <- rowsum(X, cl) / as.vector(table(cl))
  nk <- as.vector(table(cl))
  B <- sum(nk * rowSums(sweep(cent, 2, mu)^2))
  W <- sum((X - cent[as.character(cl), , drop = FALSE])^2)
  (B / (k - 1)) / (W / (n - k))
}

db_index <- function(X, cl) {
  lev <- sort(unique(cl))
  cent <- rowsum(X, cl)[as.character(lev), , drop = FALSE] /
    as.vector(table(cl)[as.character(lev)])
  S <- sapply(lev, function(g) {
    Xi <- X[cl == g, , drop = FALSE]
    mean(sqrt(rowSums(sweep(Xi, 2, cent[as.character(g), ])^2)))
  })
  M <- as.matrix(dist(cent))
  R <- outer(S, S, "+") / M
  diag(R) <- -Inf
  mean(apply(R, 1, max))
}

# Reetiqueta clústeres por tamaño descendente (1 = el más grande)
relabel_by_size <- function(cl) {
  ord <- order(-tabulate(cl))
  match(cl, ord)
}

# Asigna cada fila de X al centroide más cercano (distancia euclidiana)
assign_nearest <- function(X, centers) {
  d2 <- outer(rowSums(X^2), rep(1, nrow(centers))) - 2 * X %*% t(centers) +
    outer(rep(1, nrow(X)), rowSums(centers^2))
  max.col(-d2, ties.method = "first")
}

# Estabilidad bootstrap de k-means: réplicas en submuestras, predicción por
# centroide más cercano sobre todos los registros y ARI frente a la referencia.
kmeans_stability <- function(X, ref_cluster, k, reps, size, nstart = 10) {
  sapply(seq_len(reps), function(b) {
    ix <- sample.int(nrow(X), size, replace = TRUE)
    km <- suppressWarnings(kmeans(X[ix, ], k, nstart = nstart, iter.max = 100))
    mclust::adjustedRandIndex(assign_nearest(X, km$centers), ref_cluster)
  })
}

# ---- k-means ponderado sobre patrones únicos --------------------------
# Equivale exactamente a k-means (Lloyd) sobre los n registros, porque cada
# patrón u representa w_u registros idénticos. Al trabajar con P << n filas se
# pueden usar cientos de inicios k-means++ y alcanzar el óptimo de forma fiable.
wkmeans <- function(P, w, k, nstart = 200, iter_max = 100) {
  best <- NULL
  d2c <- function(C) outer(rowSums(P^2), rep(1, nrow(C))) - 2 * P %*% t(C) +
    outer(rep(1, nrow(P)), rowSums(C^2))
  for (s in seq_len(nstart)) {
    # inicialización k-means++ ponderada
    C <- P[sample.int(nrow(P), 1, prob = w), , drop = FALSE]
    while (nrow(C) < k) {
      dmin <- apply(pmax(d2c(C), 0), 1, min)
      pr <- w * dmin
      if (sum(pr) <= 0) pr <- w
      C <- rbind(C, P[sample.int(nrow(P), 1, prob = pr), , drop = FALSE])
    }
    cl <- integer(nrow(P))
    for (it in seq_len(iter_max)) {
      new <- max.col(-d2c(C), ties.method = "first")
      if (identical(new, cl)) break
      cl <- new
      for (g in seq_len(k)) {
        ix <- cl == g
        if (any(ix)) C[g, ] <- colSums(P[ix, , drop = FALSE] * w[ix]) / sum(w[ix])
      }
    }
    wss <- sum(w * pmax(d2c(C)[cbind(seq_len(nrow(P)), cl)], 0))
    if (is.null(best) || wss < best$wss - 1e-9) best <- list(centers = C, cluster = cl, wss = wss)
  }
  best$size <- as.vector(tapply(w, factor(best$cluster, levels = seq_len(k)), sum))
  best
}

# Estabilidad bootstrap exacta: remuestrear n registros con reemplazo equivale
# a extraer frecuencias multinomiales sobre los patrones.
wkmeans_stability <- function(P, w, pat_idx, ref_cluster, k, reps, nstart = 50) {
  n <- sum(w)
  lapply(seq_len(reps), function(b) {
    wb <- as.vector(rmultinom(1, n, w / n))
    keep <- wb > 0
    fit <- wkmeans(P[keep, , drop = FALSE], wb[keep], k, nstart = nstart)
    pc <- assign_nearest(P, fit$centers)        # asigna todos los patrones
    pc[pat_idx]                                 # etiquetas a nivel de registro
  })
}
