#!/usr/bin/env Rscript
# ==================================================================
# run_pipeline.R — Orquestador: ejecuta las 10 etapas en orden.
# Uso:  Rscript run_pipeline.R            (todas las etapas)
#       Rscript run_pipeline.R 5 10       (desde la etapa 5 hasta la 10)
# ==================================================================
invisible(suppressWarnings(Sys.setlocale("LC_ALL", "C.UTF-8")))
args <- as.integer(commandArgs(trailingOnly = TRUE))
stages <- c("01_ingest", "02_clean", "03_features", "04_normalize", "05_select_k",
            "06_cluster", "07_validate", "08_profile", "09_figures", "10_tables")
from <- if (length(args) >= 1) args[1] else 1L
to   <- if (length(args) >= 2) args[2] else length(stages)
t_all <- Sys.time()
for (s in stages[from:to]) {
  message("\n==== Etapa ", s, " ====")
  t0 <- Sys.time()
  status <- system2("Rscript", file.path("R", paste0(s, ".R")))
  if (status != 0) stop("Falló la etapa ", s, " (código ", status, ")")
  message(sprintf("     %s completada en %.1f s", s,
                  as.numeric(difftime(Sys.time(), t0, units = "secs"))))
}
source("R/utils.R")
writeLines(capture.output(sessionInfo()), "logs/sessionInfo.txt")
message(sprintf("\nPipeline completo en %.1f min",
                as.numeric(difftime(Sys.time(), t_all, units = "mins"))))
