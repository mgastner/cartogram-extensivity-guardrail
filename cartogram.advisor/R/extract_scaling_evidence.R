# extract_scaling_evidence.R — scaling evidence extraction

#' Extract scaling evidence from spatial data
#'
#' Orchestrates the full evidence extraction pipeline:
#' preprocessing -> GAM fits across k grid.
#'
#' The function fits the area-scaling GAM at each basis dimension in
#' `cfg$k_grid` and returns estimates of the area exponent gamma.
#' It does **not** apply any decision threshold (delta); that step is
#' performed externally after all fits have been collected.
#'
#' @param data An `sf` object whose rows correspond to spatial regions.
#' @param value_col Character. Name of the numeric attribute column.
#' @param population_col Character. Name of the population column.
#' @param config A `scaling_config` object created by
#'   [scaling_config()].  Defaults are used when `NULL`.
#' @param code_version Character or `NULL`. Git SHA or version tag.
#'   If `NULL`, attempts `system("git rev-parse --short HEAD")`.
#' @param notes Character or `NA_character_`. Free-text run notes.
#' @return A one-row tibble with scaling evidence, cfg metadata, and
#'   run metadata.  The headline `gamma_max` is the maximum across all
#'   k values (most conservative for a non-extensivity warning).
#' @export
extract_scaling_evidence <- function(
    data,
    value_col,
    population_col,
    config       = NULL,
    code_version = NULL,
    notes        = NA_character_
) {
  cfg <- if (is.null(config)) scaling_config() else config

  # -- Resolve run metadata --
  timestamp <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
  if (is.null(code_version)) {
    code_version <- tryCatch({
      out <- suppressWarnings(
        system("git rev-parse --short HEAD", intern = TRUE, ignore.stderr = TRUE)
      )
      if (length(out) == 1L && nzchar(out)) trimws(out) else NA_character_
    },
    error   = function(e) NA_character_,
    warning = function(w) NA_character_
    )
  }

  # -- Config metadata (constant across all rows of a single run) --
  cfg_meta <- list(
    alpha          = cfg$alpha,
    family         = cfg$family$family,
    link           = cfg$family$link,
    bs             = cfg$bs,
    k_grid         = paste(cfg$k_grid, collapse = ","),
    smooth_method  = cfg$smooth_method,
    n_min          = cfg$n_min,
    population_col = if (is.null(population_col)) NA_character_ else as.character(population_col),
    code_version   = if (is.null(code_version)) NA_character_ else as.character(code_version),
    timestamp      = timestamp,
    notes          = if (is.null(notes)) NA_character_ else as.character(notes)
  )

  # -- Early return template --
  empty_evidence <- function(reason_code, n_input = NA_integer_) {
    tibble::as_tibble(c(
      list(
        gamma_hat     = NA_real_,
        se_gamma      = NA_real_,
        gamma_max     = NA_real_,
        n_input       = as.integer(n_input),
        n_used        = NA_integer_,
        n_dropped     = NA_integer_,
        fit_converged = NA,
        warning_free  = NA,
        fit_warnings  = NA_character_,
        audit_tbl     = list(NULL),
        reason_code   = reason_code
      ),
      cfg_meta
    ))
  }

  # -- Preprocessing --
  if (is.null(population_col)) {
    return(empty_evidence("population_col_required"))
  }

  n_input <- if (inherits(data, "sf")) nrow(data) else NA_integer_
  preprocessed <- preprocess(data, value_col, population_col, cfg)

  if (is.character(preprocessed)) {
    return(empty_evidence(preprocessed, n_input))
  }

  n_used    <- nrow(preprocessed)
  n_dropped <- n_input - n_used

  # -- Fit GAM across all k values --
  audit_tbl <- audit_scaling_test(preprocessed, cfg)

  # -- Headline estimates: use the most conservative gamma_max --
  # The maximum gamma_max across all k is the most conservative for
  # a non-extensivity warning (hardest to trigger a warning).
  converged_rows <- dplyr::filter(audit_tbl, fit_converged)

  if (nrow(converged_rows) == 0L) {
    return(tibble::as_tibble(c(
      list(
        gamma_hat     = NA_real_,
        se_gamma      = NA_real_,
        gamma_max     = NA_real_,
        n_input       = as.integer(n_input),
        n_used        = as.integer(n_used),
        n_dropped     = as.integer(n_dropped),
        fit_converged = FALSE,
        warning_free  = FALSE,
        fit_warnings  = audit_tbl$fit_warnings[1],
        audit_tbl     = list(audit_tbl),
        reason_code   = "fit_failed"
      ),
      cfg_meta
    )))
  }

  # Row with the largest gamma_max (most conservative)
  best_row <- converged_rows |>
    dplyr::slice_max(gamma_max, n = 1, with_ties = FALSE)

  all_warning_free <- all(converged_rows$warning_free)
  all_warnings <- converged_rows$fit_warnings[!is.na(converged_rows$fit_warnings)]
  combined_warnings <- if (length(all_warnings) == 0L) {
    NA_character_
  } else {
    paste(unique(all_warnings), collapse = "; ")
  }

  tibble::as_tibble(c(
    list(
      gamma_hat     = best_row$gamma_hat,
      se_gamma      = best_row$se_gamma,
      gamma_max     = best_row$gamma_max,
      n_input       = as.integer(n_input),
      n_used        = as.integer(n_used),
      n_dropped     = as.integer(n_dropped),
      fit_converged = TRUE,
      warning_free  = all_warning_free,
      fit_warnings  = combined_warnings,
      audit_tbl     = list(audit_tbl),
      reason_code   = "fit_ok"
    ),
    cfg_meta
  ))
}

