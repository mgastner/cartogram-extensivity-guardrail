# cartogram_advisor

R package to test whether a spatial variable is extensive (scales with area) or intensive (does not). Intended as a guardrail for cartogram construction — area cartograms should only be used with extensive variables.

## Installation

```r
# From the repo root:
devtools::install("cartogram_advisor")

# Or load without installing:
devtools::load_all("cartogram_advisor")
```

## Usage

The input is an `sf` object with a numeric variable column and a population column:

```r
library(sf)
library(cartogram_advisor)

# Load your spatial data (must be an sf object with a CRS)
my_data <- st_read("my_regions.geojson")

# Test whether 'gdp_total' scales extensively
result <- extract_scaling_evidence(
  data           = my_data,
  value_col      = "gdp_total",
  population_col = "population"
)

# Result is a one-row tibble with:
#   gamma_max  — area-scaling exponent (≈1 for extensive, <1 for intensive)
#   se_gamma   — standard error
#   audit_tbl  — nested tibble with fits across basis dimensions
```

## How it works

For each country, the package:

1. Reprojects to an equal-area CRS and computes region areas
2. Fits a GAM: `log(Y) ~ s(log(A)) + s(log(P/A))` across a grid of basis dimensions (k)
3. Estimates the area-scaling exponent γ from the smooth term
4. Returns γ estimates for each k (the maximum is the most conservative for warning against non-extensivity)

A variable with γ ≈ 1 scales with area (extensive, suitable for cartograms). A variable with γ significantly below 1 does not (intensive, cartogram would be misleading).

## Dependencies

sf, mgcv, tibble, dplyr, purrr, tidyr
