# preprocess.R — input validation and feature engineering

# Validate and preprocess a data frame for scaling tests
#
# Checks required columns (including an 'area_km2'
# column), rejects non-finite values, and derives
# log-scale predictors x and z.
preprocess <- function(data, value_col, population_col,
                       cfg) {
  # ── 1. Validate required attribute columns ────────────
  required <- c(value_col, population_col, "area_km2")
  missing_cols <- setdiff(required, names(data))
  if (length(missing_cols) > 0) {
    return(stringr::str_c(
      "abstain:missing_columns_",
      stringr::str_c(
        missing_cols, collapse = ","
      )
    ))
  }

  # ── 2. Check column types ─────────────────────────────
  y   <- dplyr::pull(data, value_col)
  pop <- dplyr::pull(data, population_col)
  a   <- dplyr::pull(data, area_km2)

  if (!is.numeric(y)) {
    return(stringr::str_c(
      "abstain:non_numeric_", value_col
    ))
  }
  if (!is.numeric(pop)) {
    return(stringr::str_c(
      "abstain:non_numeric_", population_col
    ))
  }
  if (!is.numeric(a)) {
    return("abstain:non_numeric_area")
  }

  # ── 3. Drop missing; reject non-positive values ───────
  data <- data |>
    dplyr::filter(
      is.finite(.data[[value_col]]),
      is.finite(.data[[population_col]]),
      is.finite(area_km2),
      area_km2 > 0
    )

  if (nrow(data) == 0L) {
    return("abstain:all_observations_missing")
  }

  y   <- dplyr::pull(data, value_col)
  pop <- dplyr::pull(data, population_col)

  if (any(y <= 0)) {
    return(stringr::str_c(
      "abstain:non_positive_", value_col
    ))
  }
  if (any(pop <= 0)) {
    return(stringr::str_c(
      "abstain:non_positive_", population_col
    ))
  }

  # ── 4. Minimum-n guard ────────────────────────────────
  n <- nrow(data)
  if (n < cfg$n_min) {
    return(stringr::str_c(
      "abstain:too_few_regions_n", n,
      "_min", cfg$n_min
    ))
  }

  # ── 5. Derive log-scale predictors ────────────────────
  data |>
    dplyr::transmute(
      y          = .data[[value_col]],
      x          = log(area_km2),
      z          = log(
        .data[[population_col]] / area_km2
      ),
      area_km2   = area_km2,
      population = .data[[population_col]]
    )
}
