# ── Run all variables through the scaling evidence pipeline ───
# This script loops over all 34 variables and sources
# run_all_countries.R for each one.
# ──────────────────────────────────────────────────────────────

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

cat(sprintf("Running %d variables\n\n", length(all_variables)))
batch_start <- Sys.time()

for (v in all_variables) {
  .run_value_col <- v
  .run_population_col <- "pop_gpw"
  cat(sprintf("\n════ %s ════\n", v))
  source("scripts/run_all_countries.R", local = FALSE)
}

batch_elapsed <- round(as.numeric(difftime(Sys.time(), batch_start, units = "mins")), 1)
cat(sprintf("\n\nAll %d variables complete — total time: %.1f min\n",
            length(all_variables), batch_elapsed))
