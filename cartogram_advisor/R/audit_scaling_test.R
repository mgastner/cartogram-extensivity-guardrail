# audit_scaling_test.R — fit the scaling test across a grid of basis dimensions

#' Fit the scaling test across a grid of spline basis dimensions
#'
#' Iterates over every value in `cfg$k_grid`, runs
#' [fit_scaling_test()] for each, and records the gamma evidence.
#'
#' This function is **delta-free**: it returns only estimation results.
#'
#' @param preprocessed A tibble returned by [preprocess()].
#' @param cfg A `scaling_config` object.
#' @return A tibble with one row per `k` value, containing:
#'   `k`, `gamma_hat`, `se_gamma`, `gamma_max`, `fit_converged`,
#'   `warning_free`, `fit_warnings`.
#' @keywords internal
audit_scaling_test <- function(preprocessed, cfg) {

  audit_fields <- c("gamma_hat", "se_gamma", "gamma_max",
                    "fit_converged", "warning_free", "fit_warnings")

  purrr::map_dfr(cfg$k_grid, function(k_val) {

    cfg_i <- cfg
    cfg_i$k <- k_val

    res <- tryCatch(
      fit_scaling_test(preprocessed, cfg_i),
      error = function(e) {
        list(gamma_hat = NA_real_, se_gamma = NA_real_,
             gamma_max = NA_real_, model = NULL,
             fit_converged = FALSE, warning_free = FALSE,
             fit_warnings = paste("error:", conditionMessage(e)))
      }
    )

    # ── Build row from field subset ───────────────────────────────────────
    tibble::as_tibble(c(list(k = k_val), res[audit_fields]))
  })
}

