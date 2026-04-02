# extract_scaling_evidence.R — scaling evidence extraction

# Orchestrates the full evidence extraction pipeline:
# preprocessing, then GAM fits across the k grid.
extract_scaling_evidence <- function(
    data,
    value_col,
    population_col,
    config       = NULL,
    code_version = NULL,
    notes        = NA_character_
) {
  cfg <- if (is.null(config)) {
    scaling_config()
  } else {
    config
  }

  # ── Resolve run metadata ──────────────────────────────
  timestamp <- format(
    Sys.time(), "%Y-%m-%dT%H:%M:%S%z"
  )
  if (is.null(code_version)) {
    safe_git_hash <- purrr::possibly(
      function() {
        suppressWarnings(system(
          "git rev-parse --short HEAD",
          intern = TRUE,
          ignore.stderr = TRUE
        )) |>
          purrr::pluck(
            1, .default = NA_character_
          ) |>
          stringr::str_trim() |>
          dplyr::na_if("")
      },
      otherwise = NA_character_
    )
    code_version <- safe_git_hash()
  }

  # ── Config metadata ───────────────────────────────────
  pop_col_chr <- if (is.null(population_col)) {
    NA_character_
  } else {
    as.character(population_col)
  }
  ver_chr <- if (is.null(code_version)) {
    NA_character_
  } else {
    as.character(code_version)
  }
  notes_chr <- if (is.null(notes)) {
    NA_character_
  } else {
    as.character(notes)
  }

  cfg_meta <- list(
    alpha          = cfg$alpha,
    family         = cfg$family$family,
    link           = cfg$family$link,
    bs             = cfg$bs,
    k_grid         = stringr::str_c(
      cfg$k_grid, collapse = ","
    ),
    smooth_method  = cfg$smooth_method,
    n_min          = cfg$n_min,
    population_col = pop_col_chr,
    code_version   = ver_chr,
    timestamp      = timestamp,
    notes          = notes_chr
  )

  # ── Early return template ─────────────────────────────
  empty_evidence <- function(reason_code,
                             n_input = NA_integer_) {
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
        scaling_tests = list(NULL),
        reason_code   = reason_code
      ),
      cfg_meta
    ))
  }

  # ── Preprocessing ─────────────────────────────────────
  if (is.null(population_col)) {
    return(empty_evidence("population_col_required"))
  }

  n_input <- nrow(data)
  preprocessed <- preprocess(
    data, value_col, population_col, cfg
  )

  if (is.character(preprocessed)) {
    return(empty_evidence(preprocessed, n_input))
  }

  n_used    <- nrow(preprocessed)
  n_dropped <- n_input - n_used

  # ── Fit GAM for each basis dimension ────────────────
  scaling_tests <- fit_scaling_tests(preprocessed, cfg)

  # ── Headline estimates ────────────────────────────────
  # The maximum gamma_max across k values is the
  # headline summary.  Downstream functions use it
  # together with a threshold delta to compute
  # false-alarm and miss rates, as well as ROC-AUC.
  converged_rows <- dplyr::filter(
    scaling_tests, fit_converged
  )

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
        fit_warnings  = dplyr::first(
          scaling_tests$fit_warnings
        ),
        scaling_tests = list(scaling_tests),
        reason_code   = "fit_failed"
      ),
      cfg_meta
    )))
  }

  best_row <- converged_rows |>
    dplyr::slice_max(
      gamma_max, n = 1, with_ties = FALSE
    )

  all_warning_free <- all(converged_rows$warning_free)
  all_warnings <- converged_rows |>
    dplyr::filter(!is.na(fit_warnings)) |>
    dplyr::pull(fit_warnings)
  combined_warnings <- if (length(all_warnings) == 0L) {
    NA_character_
  } else {
    stringr::str_c(
      unique(all_warnings), collapse = "; "
    )
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
      scaling_tests = list(scaling_tests),
      reason_code   = "fit_ok"
    ),
    cfg_meta
  ))
}
