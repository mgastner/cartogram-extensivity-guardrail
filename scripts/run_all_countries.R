# ── Configuration ─────────────────────────────────────────────
# Set value_col and population_col before sourcing this script.
# Defaults are used only when running this script standalone.
value_col <- if (exists(".run_value_col")) .run_value_col else "builtup_fraction"
population_col <- if (exists(".run_population_col")) .run_population_col else "pop_gpw"
# ──────────────────────────────────────────────────────────────

devtools::load_all("cartogram.advisor")

countries <- sort(unique(dat$country_code))
n_countries <- length(countries)
start_time <- Sys.time()
results <- vector("list", n_countries)

for (i in seq_along(countries)) {
  cc <- countries[i]

  country_sf <- boundaries |>
    dplyr::filter(WB_A3 == cc) |>
    dplyr::left_join(
      dat |> dplyr::filter(country_code == cc),
      by = c("ADM1CD_c" = "adm_div_code")
    )

  evidence <- extract_scaling_evidence(
    data = country_sf,
    value_col = value_col,
    population_col = population_col,
    code_version = "benchmark"
  )

  # Keep the full evidence row, adding the country code
  results[[i]] <- evidence |>
    dplyr::mutate(country_code = cc, .before = 1)

  if (i %% 20 == 0) {
    total <- round(as.numeric(difftime(Sys.time(), start_time, units = "secs")), 1)
    cat(sprintf("[%s] %d/%d countries done (%.1f s elapsed)\n",
                value_col, i, n_countries, total))
  }
}

# Final progress message
if (n_countries %% 20 != 0) {
  total <- round(as.numeric(difftime(Sys.time(), start_time, units = "secs")), 1)
  cat(sprintf("[%s] %d/%d countries done (%.1f s elapsed)\n",
              value_col, n_countries, n_countries, total))
}

evidence_all <- dplyr::bind_rows(results)

# ── Save results to a single CSV ─────────────────────────────
# Unnest the audit_tbl so each row is one country × k combination.
# Drop the headline gamma_hat/se_gamma/gamma_max (they duplicate
# the most-conservative audit row) to avoid ambiguity.
dir.create("results", showWarnings = FALSE)

out_path <- file.path("results", paste0("evidence_", value_col, ".csv"))
evidence_all |>
  dplyr::select(-gamma_hat, -se_gamma, -gamma_max,
                -fit_converged, -warning_free, -fit_warnings) |>
  tidyr::unnest(audit_tbl) |>
  readr::write_csv(out_path)
cat(sprintf("Saved to %s\n", out_path))

evidence_all
