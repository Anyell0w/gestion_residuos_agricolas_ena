# ==================================================================
# 01_ingest.R — Ingesta por bloques del archivo crudo (datos masivos)
# ------------------------------------------------------------------
# Entrada : data/raw/FINAL_UNIFICADO.csv  (ENA 2014–2025, Cap. 600)
# Salida  : data/processed/01_ingest.rds, outputs/tables/ingest_audit.csv
# Estrategia: lectura en bloques de `chunk_size` filas con data.table::fread,
# selección temprana de columnas y tipado explícito; así el consumo de memoria
# queda acotado por el tamaño del bloque y no por el del archivo.
# ==================================================================
source("R/utils.R")
cfg <- load_config()
set.seed(cfg$project$seed)

f <- cfg$paths$raw_csv
if (!file.exists(f)) {
  stop("No se encuentra ", f, ". Ejecute scripts/download_data.sh (Zenodo) ",
       "o copie el CSV en data/raw/.")
}
log_msg("Ingesta: ", f, " (", round(file.size(f) / 2^20, 1), " MiB)", cfg = cfg)

header <- names(fread(f, nrows = 0, encoding = "UTF-8"))
header[1] <- sub("^﻿", "", header[1])          # elimina BOM
keep <- cfg$ingest$keep_cols
stopifnot(all(keep %in% header))
sel_idx <- match(keep, header)

chunk <- cfg$ingest$chunk_size
out <- list(); i <- 0L; skip <- 1L; total <- 0L
repeat {
  i <- i + 1L
  blk <- tryCatch(
    fread(f, skip = skip, nrows = chunk, header = FALSE, select = sel_idx,
          col.names = keep, colClasses = "integer", na.strings = c("", "NA"),
          encoding = "UTF-8", showProgress = FALSE),
    error = function(e) data.table())
  if (nrow(blk) == 0) break
  out[[i]] <- blk
  total <- total + nrow(blk)
  log_msg(sprintf("  bloque %02d: %s filas (acumulado %s)", i,
                  format(nrow(blk), big.mark = ","),
                  format(total, big.mark = ",")), cfg = cfg)
  if (nrow(blk) < chunk) break
  skip <- skip + chunk
}
d <- rbindlist(out); rm(out); invisible(gc())

# Verificación de integridad: filas leídas = filas del archivo
n_lines <- length(count.fields(f, sep = ",", quote = "", blank.lines.skip = TRUE)) - 1L
stopifnot(nrow(d) == n_lines)

audit <- data.table(
  archivo      = basename(f),
  md5          = unname(tools::md5sum(f)),
  tamano_MiB   = round(file.size(f) / 2^20, 2),
  filas        = nrow(d),
  columnas_orig = length(header),
  columnas_cargadas = ncol(d),
  bloques      = i,
  memoria_MiB  = round(as.numeric(object.size(d)) / 2^20, 2),
  anios        = paste(sort(unique(d$ANIO)), collapse = ";")
)
fwrite(audit, file.path(cfg$paths$tables, "ingest_audit.csv"))
saveRDS(d, file.path(cfg$paths$interim, "01_ingest.rds"), compress = "xz")
log_msg("Ingesta completada: ", nrow(d), " filas x ", ncol(d), " columnas", cfg = cfg)
