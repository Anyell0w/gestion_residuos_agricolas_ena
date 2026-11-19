# ==================================================================
# 10_tables.R — Tablas LaTeX y macros numéricas para el artículo
# ------------------------------------------------------------------
# Genera paper/tables/*.tex (booktabs) y paper/tables/numeros.tex, con una
# macro \newcommand por cada cifra citada en el texto: el artículo se
# actualiza automáticamente si cambian los datos o la configuración.
# ==================================================================
source("R/utils.R")
cfg <- load_config()
T <- function(f) fread(file.path(cfg$paths$tables, f), encoding = "UTF-8")
out <- function(txt, f) writeLines(enc2utf8(txt), file.path(cfg$paths$paper_tables, f), useBytes = TRUE)
fmt <- function(x, d = 3) formatC(x, format = "f", digits = d)
big <- function(x) gsub(",", "\\\\,", formatC(x, format = "d", big.mark = ","))
pct <- function(x, d = 1) formatC(100 * x, format = "f", digits = d)
esc <- function(x) gsub("([&%_#])", "\\\\\\1", x)
tt  <- function(x) paste0("\\texttt{", gsub("_", "\\\\_", x), "}")

desc <- T("descriptivos_15var.csv"); norm <- T("normalizacion.csv")
flow <- T("flujo_depuracion.csv");   sel  <- T("seleccion_k.csv")
val  <- T("validacion_por_cluster.csv"); vg <- T("validacion_global.csv")
ari  <- T("concordancia_ari.csv");   asc  <- T("perfil_asociacion.csv")
trd  <- T("perfil_tendencia.csv");   comp <- T("compresion_patrones.csv")
aud  <- T("ingest_audit.csv");       prof <- T("perfil_centroides.csv")
cr   <- T("perfil_region.csv")
nm   <- unlist(cfg$cluster_names)

# Tabla I — Flujo de depuración -------------------------------------------------
out(c("\\begin{table}[!htb]", "\\centering", "\\caption{Flujo de depuración de registros}",
      "\\label{tab:flujo}", "\\footnotesize", "\\begin{tabular}{@{}lrr@{}}", "\\toprule",
      "Paso & Registros & Retenido (\\%) \\\\", "\\midrule",
      flow[, sprintf("%s & %s & %s \\\\", esc(paso), big(n), fmt(retenido_pct, 2))],
      "\\bottomrule", "\\end{tabular}", "\\end{table}"), "tab_flujo.tex")

# Tabla II — Variables: descripción, normalización y prevalencia ------------------
d <- merge(VARS15[, .(var, rol)], desc, by = "var", sort = FALSE)
d[, `:=`(media = global, de = sd)]
d[, `:=`(z_si_0 = -media / de, z_si_1 = (1 - media) / de)]
d <- d[match(VARS15$var, var)]
rows <- character(); prev_blk <- ""
for (i in seq_len(nrow(d))) {
  r <- d[i]
  if (r$bloque != prev_blk) {
    tag <- if (r$rol == "Agrupamiento") "activa" else "ilustrativa"
    rows <- c(rows, sprintf("\\multicolumn{10}{@{}l}{\\textit{%s} (%s)}\\\\", r$bloque, tag))
    prev_blk <- r$bloque
  }
  rows <- c(rows, sprintf("%s & %s & %s & %s & %s & %s & %s & %s & %s & %s \\\\",
                          tt(r$var), esc(sub("^Residuos (de cultivo|pecuarios): ", "", r$etiqueta)),
                          tt(r$origen), fmt(r$media), fmt(r$de), fmt(r$z_si_0, 2), fmt(r$z_si_1, 2),
                          pct(r$Costa), pct(r$Sierra), pct(r$Selva)))
}
out(c("\\begin{table*}[!t]", "\\centering",
      "\\caption{Variables del estudio: definición, normalización y prevalencia por región natural ($n=\\nValid$)}",
      "\\label{tab:variables}", "\\footnotesize", "\\setlength{\\tabcolsep}{3.5pt}",
      "\\begin{tabular}{@{}lllrrrrrrr@{}}", "\\toprule",
      "Variable & Descripción & Origen (Cap.~600) & Media & DE & $z_{x=0}$ & $z_{x=1}$ & Costa \\% & Sierra \\% & Selva \\% \\\\",
      "\\midrule", rows, "\\bottomrule", "\\end{tabular}",
      "\\par\\smallskip\\parbox{\\textwidth}{\\scriptsize Nota: todas las variables son binarias (1~=~sí). Las 9 variables \\textit{activas} definen los grupos; las 6 \\textit{ilustrativas} solo los describen. La normalización min--max deja los valores sin cambio (mín.~=~0, máx.~=~1), por lo que la media es la prevalencia. $z_{x=0}$ y $z_{x=1}$: valores tipificados usados en el análisis de sensibilidad. ``$|$'': cualquiera de las opciones.}",
      "\\end{table*}"), "tab_variables.tex")

# Tabla III — Selección de k ------------------------------------------------------
kf <- sel[elegido == TRUE, k]
out(c("\\begin{table}[!htb]", "\\centering",
      "\\caption{Criterios para elegir el número de grupos}",
      "\\label{tab:seleccionk}", "\\footnotesize", "\\setlength{\\tabcolsep}{3.2pt}",
      "\\begin{tabular}{@{}rrrrrrr@{}}", "\\toprule",
      "$k$ & WSS & CH & DB & Silueta & ARI & Mín. (\\%) \\\\", "\\midrule",
      sel[, sprintf("%s%s & %s & %s & %s & %s & %s & %s \\\\",
                    ifelse(elegido, "\\rowcolor{SelRow}", ""), k, big(round(wss)),
                    big(round(ch)), fmt(db), fmt(sil_mean), fmt(ari_mean), fmt(min_cluster_pct, 1))],
      "\\bottomrule", "\\end{tabular}",
      "\\par\\smallskip\\parbox{\\columnwidth}{\\scriptsize WSS: suma de cuadrados intra-grupo; CH: Calinski--Harabasz ($\\uparrow$); DB: Davies--Bouldin ($\\downarrow$); silueta media en 10 submuestras de 8\\,000 registros ($\\uparrow$); ARI: estabilidad media en 20 réplicas \\textit{bootstrap} ($\\uparrow$); Mín.: tamaño del grupo más pequeño. Fila sombreada: $k$ elegido (ARI $\\geq$ 0.80, Mín. $\\geq$ 5\\,\\% y menor DB).}",
      "\\end{table}"), "tab_seleccion_k.tex")

# Tabla IV — Perfil de los grupos (prevalencias, %) --------------------------------
pw <- dcast(prof, var ~ CLUSTER, value.var = "prev")
pw <- merge(VARS15[, .(var, etiqueta, rol, bloque)], pw, by = "var", sort = FALSE)
pw <- pw[match(VARS15$var, var)]
glob <- desc[match(pw$var, var), global]
rws <- character(); prev_rol <- ""
for (i in seq_len(nrow(pw))) {
  if (pw$rol[i] != prev_rol) {
    rws <- c(rws, if (prev_rol != "") "\\midrule" else NULL,
             sprintf("\\multicolumn{5}{@{}l}{\\textit{Variables %s}}\\\\",
                     if (pw$rol[i] == "Agrupamiento") "activas (residuos)" else "ilustrativas"))
    prev_rol <- pw$rol[i]
  }
  vals <- unlist(pw[i, nm, with = FALSE])
  cells <- sapply(vals, function(x) {
    s <- pct(x, 0)
    if (pw$rol[i] == "Agrupamiento" && x >= 0.5) paste0("\\textbf{", s, "}") else s })
  lab <- esc(sub("^Residuos de cultivo: ", "Cultivo: ",
                 sub("^Residuos pecuarios: ", "Pecuario: ", pw$etiqueta[i])))
  rws <- c(rws, sprintf("%s & %s & %s \\\\", lab, paste(cells, collapse = " & "), pct(glob[i], 0)))
}
hdr <- paste(sub(" .*", "", nm), collapse = " & ")
out(c("\\begin{table}[!htb]", "\\centering", "\\caption{Perfil de los grupos: productores que realizan cada práctica (\\%)}",
      "\\label{tab:perfil}", "\\footnotesize", "\\setlength{\\tabcolsep}{3.5pt}",
      "\\begin{tabular}{@{}lrrrr@{}}", "\\toprule",
      paste0("Práctica & ", hdr, " & Total \\\\"),
      sprintf("$n$ & %s & %s & %s & %s \\\\", big(val$n[1]), big(val$n[2]), big(val$n[3]), big(sum(val$n))),
      "\\midrule", rws, "\\bottomrule", "\\end{tabular}",
      sprintf("\\par\\smallskip\\parbox{\\columnwidth}{\\scriptsize %s. En negrita, prevalencias $\\geq$ 50\\,\\%% en las variables activas.}",
              paste(sprintf("%s: %s", sub(" .*", "", nm), sub("^C[0-9]+ ", "", nm)), collapse = "; ")),
      "\\end{table}"), "tab_perfil.tex")

# Tabla V — Validación por grupo ---------------------------------------------------
val[, nombre := nm[cluster]]
out(c("\\begin{table}[!htb]", "\\centering", "\\caption{Tamaño, cohesión y estabilidad de los grupos}",
      "\\label{tab:validacion}", "\\footnotesize", "\\setlength{\\tabcolsep}{3pt}",
      "\\begin{tabular}{@{}lrrrr@{}}", "\\toprule",
      "Grupo & $n$ & \\% & Silueta & Jaccard \\\\", "\\midrule",
      val[, sprintf("%s & %s & %s & %s & %s \\\\", nombre, big(n), fmt(pct, 1),
                    fmt(sil_media), fmt(jaccard_media))],
      "\\bottomrule", "\\end{tabular}", "\\end{table}"), "tab_validacion.tex")

# Tabla VI — Concordancia entre métodos (ARI) -----------------------------------------
m <- as.matrix(ari[, -1]); rownames(m) <- ari$metodo
cells <- sapply(seq_len(nrow(m)), function(i) paste(sapply(seq_len(ncol(m)), function(j)
  if (j < i) fmt(m[i, j]) else if (j == i) "--" else ""), collapse = " & "))
out(c("\\begin{table}[!htb]", "\\centering", "\\caption{Concordancia entre métodos de agrupamiento (ARI)}",
      "\\label{tab:ari}", "\\footnotesize", "\\begin{tabular}{@{}lcccc@{}}", "\\toprule",
      paste0("Método & ", paste(colnames(m), collapse = " & "), " \\\\"), "\\midrule",
      paste0(rownames(m), " & ", cells, " \\\\"), "\\bottomrule", "\\end{tabular}",
      "\\end{table}"), "tab_ari.tex")

# Macros numéricas ----------------------------------------------------------------------
P <- function(cl, v) prof[CLUSTER == nm[cl] & var == v, prev]
R <- function(reg, cl) cr[REGION_LAB == reg & CLUSTER == nm[cl], pct]
G <- function(v, col = "global") desc[var == v][[col]]
mac <- c(
  nRaw = big(aud$filas), nValid = big(flow[.N, n]), pValid = fmt(flow[.N, retenido_pct], 1),
  sizeMiB = fmt(aud$tamano_MiB, 1), nChunks = aud$bloques, nPatterns = big(comp$patrones_unicos),
  compRate = fmt(comp$tasa_compresion, 0), kFinal = kf,
  silK = fmt(sel[k == kf, sil_mean]), dbK = fmt(sel[k == kf, db]),
  ariK = fmt(sel[k == kf, ari_mean]), ariKfour = fmt(sel[k == kf + 1, ari_mean]),
  ariBoot = fmt(vg$ari_media), ariBootSd = fmt(vg$ari_sd),
  jacMin = fmt(min(val$jaccard_media)), jacMax = fmt(max(val$jaccard_media)),
  ariWard = fmt(m["Ward", "k-means"]), ariClara = fmt(m["CLARA", "k-means"]),
  ariZ = fmt(m["k-means (z)", "k-means"]),
  pctCone = fmt(val[cluster == 1, pct], 1), pctCtwo = fmt(val[cluster == 2, pct], 1),
  pctCthree = fmt(val[cluster == 3, pct], 1),
  VRegion = fmt(asc[covariable == "Región natural", V]),
  VDep = fmt(asc[covariable == "Departamento", V]), VAnio = fmt(asc[covariable == "Año", V]),
  CoRaAbono = pct(P(1, "RA_ABONO"), 0), CoRcAlim = pct(P(1, "RC_ALIMENTO"), 0),
  CoRcAbono = pct(P(1, "RC_ABONO"), 0), CoComb = pct(P(1, "RA_COMBUST"), 0),
  CtwoQuema = pct(P(2, "RC_QUEMA"), 0), CtwoRaInad = pct(P(2, "RA_INADEC"), 0),
  CtwoBota = pct(P(2, "RC_BOTA"), 0), CtwoRaAbono = pct(P(2, "RA_ABONO"), 0),
  CtwoRcCampo = pct(P(2, "RC_CAMPO"), 0), CtwoRcAlim = pct(P(2, "RC_ALIMENTO"), 0),
  CthreeRaCampo = pct(P(3, "RA_CAMPO"), 0), CthreeRcCampo = pct(P(3, "RC_CAMPO"), 0),
  CthreeQuema = pct(P(3, "RC_QUEMA"), 0), CthreeAlmInad = pct(P(3, "ALM_INADEC"), 0),
  CoAlmInad = pct(P(1, "ALM_INADEC"), 0), CtwoAlmInad = pct(P(2, "ALM_INADEC"), 0),
  CtwoConoce = pct(P(2, "CONOCE_ID"), 0), CoConoce = pct(P(1, "CONOCE_ID"), 0),
  CoMina = pct(P(1, "MINA"), 1), CthreeMina = pct(P(3, "MINA"), 1),
  SierraCone = fmt(R("Sierra", 1), 0), CostaCtwo = fmt(R("Costa", 2), 0),
  SelvaCthree = fmt(R("Selva", 3), 0),
  globQuema = pct(G("RC_QUEMA"), 1), costaQuema = pct(G("RC_QUEMA", "Costa"), 1),
  globCampo = pct(G("RC_CAMPO"), 1), selvaCampo = pct(G("RC_CAMPO", "Selva"), 1),
  sierraRaAbono = pct(G("RA_ABONO", "Sierra"), 1), globRaAbono = pct(G("RA_ABONO"), 1),
  globMina = pct(G("MINA"), 1), globInfo = pct(G("INFO_EST"), 1),
  globCert = pct(G("CERTIF"), 1), globConoce = pct(G("CONOCE_ID"), 1),
  globRcAlim = pct(G("RC_ALIMENTO"), 1)
)
out(sprintf("\\newcommand{\\%s}{%s}", names(mac), mac), "numeros.tex")
unlink(file.path(cfg$paths$paper_tables, "tab_variables_old.tex"))
log_msg("Tablas LaTeX y ", length(mac), " macros escritas en ", cfg$paths$paper_tables, cfg = cfg)
