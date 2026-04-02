# evaluate.R — classification performance metrics

# ── Ground truth: extensive variable names ──────────────
# All other analysed variables are treated as
# non-extensive.
.EXTENSIVE_VARS <- c(
  "builtup_km2_2020",
  "builtup_volume_2020",
  "burned_area_pixels_2020",
  "co2_emissions_2020",
  "cropland_area_km2",
  "et_total_mm_km2_2020",
  "forest_area_km2",
  "forest_loss_pixels",
  "gdp_total_2020",
  "nightlights_sum_2020",
  "pm25_total_2019",
  "pop_ghsl",
  "pop_wp",
  "precip_total_mm_km2",
  "tree_cover_km2_2000",
  "urban_area_km2",
  "water_area_km2"
)

# Read all evidence CSVs and compute headline
# gamma_max per (country, variable).
#
# Returns a tibble with columns: country_code,
# gamma_max, variable, is_extensive.
read_all_evidence <- function(
    results_dir = "results"
) {
  csv_files <- fs::dir_ls(
    results_dir, glob = "*.csv"
  )

  purrr::map_dfr(csv_files, \(f) {
    var_name <- f |>
      fs::path_file() |>
      stringr::str_remove("^evidence_") |>
      stringr::str_remove("\\.csv$")

    readr::read_csv(
      f, show_col_types = FALSE
    ) |>
      dplyr::filter(fit_converged) |>
      dplyr::group_by(country_code) |>
      dplyr::summarise(
        gamma_max = max(
          gamma_max, na.rm = TRUE
        ),
        .groups = "drop"
      ) |>
      dplyr::mutate(
        variable     = var_name,
        is_extensive = var_name %in%
          .EXTENSIVE_VARS
      )
  })
}

# False-alarm and miss rates for a given delta
#
# A warning fires when gamma_max < 1 - delta.
# False alarm: truly extensive but flagged
#   (gamma_max < 1 - delta).
# Miss: truly non-extensive but not flagged
#   (gamma_max >= 1 - delta).
#
# Returns a one-row tibble with columns
# delta, false_alarm, miss.
error_rates <- function(evidence,
                        delta = 0.2) {
  valid <- evidence |>
    dplyr::filter(!is.na(gamma_max))

  fa <- valid |>
    dplyr::filter(is_extensive) |>
    dplyr::summarise(
      rate = mean(gamma_max < 1 - delta)
    ) |>
    dplyr::pull(rate)

  miss <- valid |>
    dplyr::filter(!is_extensive) |>
    dplyr::summarise(
      rate = mean(gamma_max >= 1 - delta)
    ) |>
    dplyr::pull(rate)

  tibble::tibble(
    delta       = delta,
    false_alarm = fa,
    miss        = miss
  )
}

# ROC-AUC via rank-based Mann-Whitney formula
#
# Measures how well gamma_max separates extensive
# from non-extensive variables.  AUC near 1 means
# extensive observations consistently have higher
# gamma_max than non-extensive ones.
roc_auc <- function(evidence) {
  scores <- evidence |>
    dplyr::filter(!is.na(gamma_max))

  ext <- scores |>
    dplyr::filter(is_extensive)
  nonext <- scores |>
    dplyr::filter(!is_extensive)

  n_ext    <- nrow(ext)
  n_nonext <- nrow(nonext)

  if (n_ext == 0L || n_nonext == 0L) {
    return(NA_real_)
  }

  all_scores <- dplyr::bind_rows(ext, nonext)
  r <- rank(
    dplyr::pull(all_scores, gamma_max)
  )
  sum_ext <- sum(r[seq_len(n_ext)])

  (sum_ext - n_ext * (n_ext + 1) / 2) /
    (n_ext * n_nonext)
}
