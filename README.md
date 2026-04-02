# cartogram-extensivity-guardrail

Empirical scaling evidence for distinguishing extensive and non-extensive
variables in cartogram construction. Companion repository for:

> Singhania, A., Tharatipyakul, A., Miaji, N.Z. and Gastner, M.T. (2026).
> Does Your Mapped Variable Add Up? Statistical Guardrails for Web-Based
> Cartogram Generation. *EuroCarto 2026*.

## Repository structure

```
├── data/               CSV benchmark data and GeoJSON boundaries
├── R/                  Analysis functions (sourced, not a package)
├── scripts/            Pipeline scripts to reproduce results
├── renv.lock           Pinned R package versions
└── README.md
```

## Quick start

```r
# 1. Install renv (only needed once)
install.packages("renv")

# 2. Restore the exact package versions used by the
#    authors (recorded in renv.lock)
renv::restore()

# 3. Reproduce all results
source("scripts/replicate.R")
```

## Dependencies

This repository uses
[renv](https://rstudio.github.io/renv/) to pin the
exact R package versions used when producing the results
in the paper.  Running `renv::restore()` installs those
versions into a project-local library so that the
pipeline behaves identically regardless of what is
installed system-wide.  Core packages:
sf, mgcv, tibble, dplyr, purrr, tidyr, readr.
