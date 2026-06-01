# cartogram-extensivity-guardrail

Empirical scaling evidence for distinguishing extensive and non-extensive
variables in cartogram construction. Companion repository for:

> Singhania, A., Tharatipyakul, A., Miaji, N.Z. and Gastner, M.T. (2026).
> Does Your Mapped Variable Add Up? Statistical Guardrails for Web-Based
> Cartogram Generation. Under review.

## Related projects

- **This repository:**
  <https://github.com/mgastner/cartogram-extensivity-guardrail>
- **Python implementation:** the guardrail is implemented in
  [`go-cart-io/cartogram-web`](https://github.com/go-cart-io/cartogram-web)
  and runs live on [go-cart.io](https://go-cart.io) from **v4.6.0**
  onward.

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
├── .R-version          Pinned R version (4.5.2) for rig
├── renv.lock           Pinned package versions (P3M binary snapshot)
└── README.md
```

## Quick start

This project pins **R 4.5.2** and installs every package as a
**prebuilt binary** from a frozen package-manager snapshot, so nothing
is ever compiled from source.

```bash
# 1. Install the exact R version with rig
#    (https://github.com/r-lib/rig). rig downloads the official
#    prebuilt R binary — no compilation.
rig add 4.5.2
rig default 4.5.2
```

```r
# 2. Install renv (only needed once)
install.packages("renv")

# 3. Restore the pinned package versions — all prebuilt binaries
#    from the P3M snapshot recorded in renv.lock
renv::restore()

# 4. Fit GAMs for all benchmark variables
source("scripts/fit_all_variables.R")

# 5. Compute ROC-AUC and error rates from cached results
source("scripts/compute_error_rates.R")
```

## Dependencies

This repository pins both the **R version** and every **package
version**, and resolves all packages from prebuilt binaries, so the
pipeline installs identically — without compiling anything from
source — on any machine.

- **R is pinned to 4.5.2.** Install it with
  [rig](https://github.com/r-lib/rig) (`rig add 4.5.2`), which downloads
  the official prebuilt R binary. The `.R-version` file records this
  pin. The recommended packages bundled with R 4.5.2 (`Matrix`, `mgcv`,
  `nlme`, `lattice`) are used as shipped, so they are never recompiled.
  This is deliberate: on a newer R, `renv.lock`'s pinned `Matrix`
  version is no longer the current one on CRAN, so R would otherwise
  try to compile it from source.
- **Packages are pinned in [`renv.lock`](renv.lock)** and resolved from
  a frozen [Posit Public Package Manager](https://packagemanager.posit.co/)
  snapshot (`.../cran/2026-05-15`). Every pinned version is available as
  a prebuilt binary for R 4.5.2, so `renv::restore()` installs binaries
  only and never falls back to a source build.

Core packages: mgcv, dplyr, purrr, tibble, readr, stringr, cli, fs,
tidyr.
