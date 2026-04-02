# Run scaling evidence extraction for all countries
#
# Fits the area-scaling GAM to every country and saves
# results as a CSV.
run_all_countries <- function(value_col,
                              population_col,
                              dat) {
  countries <- sort(unique(dat$country_code))
  results <- purrr::map(
    cli::cli_progress_along(
      countries,
      format = stringr::str_c(
        "[{value_col}] ",
        "{cli::pb_current}/{cli::pb_total} ",
        "({cli::pb_elapsed})"
      )
    ),
    \(i) {
      cc <- countries[i]
      country_dat <- dat |>
        dplyr::filter(country_code == cc)

      evidence <- extract_scaling_evidence(
        data           = country_dat,
        value_col      = value_col,
        population_col = population_col,
        code_version   = "benchmark"
      )

      evidence |>
        dplyr::mutate(
          country_code = cc, .before = 1
        )
    }
  )

  evidence_all <- dplyr::bind_rows(results)

  # ── Save results to a single CSV ───────────────────────
  # Unnest scaling_tests so each row is one country x k
  # combination.  Drop headline gamma_hat/se_gamma/
  # gamma_max (they duplicate the row with the largest
  # gamma_max).
  fs::dir_create("results")

  out_path <- fs::path(
    "results",
    stringr::str_c(
      "evidence_", value_col, ".csv"
    )
  )
  evidence_all |>
    dplyr::select(
      -gamma_hat, -se_gamma, -gamma_max,
      -fit_converged, -warning_free,
      -fit_warnings
    ) |>
    tidyr::unnest(scaling_tests) |>
    readr::write_csv(out_path)
  cli::cli_alert_success(
    "Saved to {.path {out_path}}"
  )

  evidence_all
}
