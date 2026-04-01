# Scripts

## Replication

```r
# Install dependencies
install.packages(c("sf", "mgcv", "tibble", "dplyr", "purrr", "tidyr", "readr", "devtools"))

# From the repo root:
source("scripts/replicate.R")
```

This loads the data, fits a GAM-based area-scaling exponent for each of 34 variables across all countries, and writes per-variable CSVs to `results/`.

## Files

- `replicate.R` — Entry point. Loads boundaries and dataset, then sources `run_all_variables.R`.
- `run_all_variables.R` — Loops over all 34 variables (17 intensive + 17 extensive).
- `run_all_countries.R` — For each variable, runs `extract_scaling_evidence()` per country using the `cartogram.advisor` package.

## Requirements

- R ≥ 4.1
- `cartogram.advisor/` R package (included in this repo)
- `data/admin1_all_variables.csv` and `data/world_bank_boundaries_simplified.geojson`
