# fit_all_variables.R — Fit area-scaling GAMs
# for all 34 benchmark variables
#
# Usage:
#   Rscript scripts/fit_all_variables.R

library(dplyr)
library(readr)

# Source analysis functions
r_files <- sort(fs::dir_ls("R", glob = "*.R"))
purrr::walk(r_files, source)
source("scripts/fit_single_variable.R")

# Load data
dat <- read_csv(
  "data/admin1_all_variables.csv",
  show_col_types = FALSE
)

# ── 34 benchmark variables ──────────────────────────
all_variables <- c(
  "builtup_fraction",
  "builtup_km2_2020",
  "builtup_volume_2020",
  "burned_area_pixels_2020",
  "cloud_fraction_mean",
  "co2_emissions_2020",
  "cropland_area_km2",
  "elevation_mean_m",
  "et_mean_mm_2020",
  "et_total_mm_km2_2020",
  "forest_area_km2",
  "forest_fraction",
  "forest_loss_pixels",
  "gdp_per_capita_2020",
  "gdp_total_2020",
  "ndvi_mean_2020",
  "nightlights_per_km2",
  "nightlights_sum_2020",
  "pm25_annual_2019",
  "pm25_total_2019",
  "pop_ghsl",
  "pop_wp",
  "precip_annual_mm",
  "precip_total_mm_km2",
  "ruggedness_mean",
  "soil_organic_carbon_g_per_kg",
  "temp_annual_mean_C",
  "travel_time_to_city_min",
  "tree_cover_km2_2000",
  "tree_cover_pct_2000",
  "urban_area_km2",
  "urban_fraction",
  "water_area_km2",
  "water_occurrence_pct"
)

# ── Fit all variables ───────────────────────────────
cli::cli_alert_info(
  "Fitting {length(all_variables)} variables"
)
batch_start <- Sys.time()

purrr::walk(all_variables, \(v) {
  cli::cli_h2(v)
  fit_single_variable(
    value_col      = v,
    population_col = "pop_gpw",
    dat            = dat
  )
})

batch_elapsed <- round(as.numeric(difftime(
  Sys.time(), batch_start, units = "mins"
)), 1)
cli::cli_alert_success(stringr::str_c(
  "All {length(all_variables)} variables",
  " complete \u2014 {batch_elapsed} min"
))
