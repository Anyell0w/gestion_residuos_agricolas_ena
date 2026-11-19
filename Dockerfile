# Entorno congelado: R 4.3.3 + paquetes + TeX Live para el artículo
FROM rocker/r-ver:4.3.3
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      make curl ca-certificates libcairo2-dev \
      texlive-latex-base texlive-latex-recommended texlive-latex-extra \
      texlive-publishers texlive-lang-spanish texlive-fonts-recommended \
      texlive-pictures \
    && rm -rf /var/lib/apt/lists/*
COPY install_packages.R /tmp/install_packages.R
RUN Rscript /tmp/install_packages.R
WORKDIR /work
CMD ["make", "all"]
