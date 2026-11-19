# ==================================================================
# install_packages.R — Instala las dependencias del pipeline
# Versiones de referencia (entorno de desarrollo, R 4.3.3) en
# logs/sessionInfo.txt. Para un entorno congelado use el Dockerfile.
# ==================================================================
pkgs <- c("data.table", "yaml", "ggplot2", "cluster", "mclust",
          "patchwork", "scales", "ggrepel")
repos <- "https://cloud.r-project.org"
missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing, repos = repos)
invisible(lapply(pkgs, function(p) cat(sprintf("%-12s %s\n", p, packageVersion(p)))))
