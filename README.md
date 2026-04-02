# cartogram-extensivity-guardrail

Empirical scaling evidence for distinguishing extensive and non-extensive
variables in cartogram construction. Companion repository for:

> Singhania, A., Tharatipyakul, A., Miaji, N.Z. and Gastner, M.T. (2026).
> Does Your Mapped Variable Add Up? Statistical Guardrails for Web-Based
> Cartogram Generation. Under review.

## Repository structure

```
├── data/               CSV benchmark data and GeoJSON boundaries
├── R/                  Analysis functions (sourced, not a package)
│   ├── config.R                  Hyperparameters and scaling_config()
│   ├── preprocess.R              Data validation and log-scale predictors
│   ├── fit_scaling_tests.R       GAM fitting across k values
│   ├── extract_scaling_evidence.R  Pipeline orchestration
│   └── evaluate.R                ROC-AUC and error-rate metrics
├── scripts/            Pipeline entry points
│   ├── fit_all_variables.R       Fit GAMs for all 34 variables
│   ├── fit_single_variable.R     Fit GAMs for one variable
│   └── compute_error_rates.R     Report ROC-AUC and error rates
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

# 3. Fit GAMs for all benchmark variables
source("scripts/fit_all_variables.R")

# 4. Compute ROC-AUC and error rates from cached results
source("scripts/compute_error_rates.R")
```

## Dependencies

This repository uses
[renv](https://rstudio.github.io/renv/) to pin the
exact R package versions used when producing the results
in the paper.  Running `renv::restore()` installs those
versions into a project-local library so that the
pipeline behaves identically regardless of what is
installed system-wide.  Core packages:
mgcv, dplyr, purrr, tibble, readr, stringr, cli, fs.
