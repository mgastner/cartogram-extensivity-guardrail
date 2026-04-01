# preprocess.R — input validation and feature engineering

# Equal-area CRS used for all area computations.
.EQUAL_AREA_CRS <- "ESRI:54009"  # Mollweide

#' Validate and preprocess an sf upload
#'
#' Checks required columns, rejects non-finite values, reprojects to an
#' equal-area CRS, computes area \eqn{A_i} in km², and derives
#' \eqn{x_i = \log A_i} and \eqn{z_i = \log(P_i / A_i)}.
#'
#' @param data An `sf` object.
#' @param value_col Name of the numeric attribute column (\eqn{Y_i}).
#' @param population_col Name of the population column (\eqn{P_i}).
#' @param cfg A `scaling_config` object.
#' @return A tibble with columns `y`, `x` (\eqn{\log A}), `z`
#'   (\eqn{\log(P/A)}), `area_km2`, and `population`.  Returns a length-one
#'   character string `"abstain:<reason>"` if preprocessing fails.
#' @keywords internal
preprocess <- function(data, value_col, population_col, cfg) {
  # ── 1. Require sf and valid CRS ────────────────────────────────────────────
  if (!inherits(data, "sf")) {
    return("abstain:input_not_sf")
  }
  if (is.na(sf::st_crs(data))) {
    return("abstain:missing_crs")
  }

  # ── 2. Validate required attribute columns ─────────────────────────────────
  missing_cols <- setdiff(c(value_col, population_col), names(data))
  if (length(missing_cols) > 0) {
    return(paste0("abstain:missing_columns_", paste(missing_cols, collapse = ",")))
  }

  # ── 3. Extract y and population; check numeric ─────────────────────────────
  y   <- data[[value_col]]
  pop <- data[[population_col]]

  if (!is.numeric(y)) {
    return(paste0("abstain:non_numeric_", value_col))
  }
  if (!is.numeric(pop)) {
    return(paste0("abstain:non_numeric_", population_col))
  }

  # ── 4. Drop missing observations; reject non-positive values ───────────
  # Drop rows where y or population is NA / NaN / Inf / -Inf.  Remaining
  # finite observations are kept even if negative *after* a later log
  # transform — negative log-values are perfectly valid.
  keep <- is.finite(y) & is.finite(pop)
  data <- data[keep, ]
  y    <- y[keep]
  pop  <- pop[keep]

  if (length(y) == 0L) {
    return("abstain:all_observations_missing")
  }

  # Non-positive y: the classifier abstains because the Gamma family
  # requires strictly positive responses, and non-positive values are
  # incompatible with the extensivity modelling framework.
  # (The cartogram generator should independently warn about non-positive
  # input; that task is not this classifier's job.)
  if (any(y <= 0)) {
    return(paste0("abstain:non_positive_", value_col))
  }
  if (any(pop <= 0)) {
    return(paste0("abstain:non_positive_", population_col))
  }

  # ── 5. Reproject to equal-area CRS and compute area in km² ────────────────
  data_ea  <- sf::st_transform(data, crs = .EQUAL_AREA_CRS)
  area_m2  <- as.numeric(sf::st_area(data_ea))
  area_km2 <- area_m2 / 1e6

  # Drop regions with invalid or zero area (e.g., empty geometries,
  # corrupted points) and proceed with the remaining observations.
  valid_area <- is.finite(area_km2) & (area_km2 > 0)
  data     <- data[valid_area, ]
  y        <- y[valid_area]
  pop      <- pop[valid_area]
  area_km2 <- area_km2[valid_area]

  if (length(y) == 0L) {
    return("abstain:invalid_area")
  }

  # ── 6. Minimum-n guard ─────────────────────────────────────────────────────
  n <- nrow(data)
  if (n < cfg$n_min) {
    return(paste0("abstain:too_few_regions_n", n, "_min", cfg$n_min))
  }

  # ── 7. Derive log-scale predictors ─────────────────────────────────────────
  density <- pop / area_km2   # P_i / A_i  (persons per km²)

  x       <- log(area_km2)    # x_i = log(A_i)
  z       <- log(density)     # z_i = log(P_i / A_i)

  # ── 8. Return tidy tibble ──────────────────────────────────────────────────
  tibble::tibble(
    y          = y,
    x          = x,
    z          = z,
    area_km2   = area_km2,
    population = pop
  )
}