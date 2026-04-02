# fit_scaling_tests.R — scaling tests across k

# Fit the area-scaling GAM for each basis dimension in
# cfg$k_grid.  Returns estimation results only; the
# decision threshold (delta) is applied downstream
# when computing false-alarm and miss rates.
fit_scaling_tests <- function(preprocessed, cfg) {
  result_fields <- c(
    "gamma_hat", "se_gamma", "gamma_max",
    "fit_converged", "warning_free", "fit_warnings"
  )

  safe_fit <- purrr::possibly(
    fit_single_k,
    otherwise = list(
      gamma_hat     = NA_real_,
      se_gamma      = NA_real_,
      gamma_max     = NA_real_,
      model         = NULL,
      fit_converged = FALSE,
      warning_free  = FALSE,
      fit_warnings  = "error: GAM fitting failed"
    )
  )

  purrr::map_dfr(cfg$k_grid, function(k_val) {
    cfg_i <- cfg
    cfg_i$k <- k_val
    res <- safe_fit(preprocessed, cfg_i)

    tibble::as_tibble(
      c(list(k = k_val), res[result_fields])
    )
  })
}

# ── Single-k helper (not exported) ─────────────────────
# Fits log(mu) = a + gamma * x + s(z) and computes a
# one-sided upper confidence bound gamma_max.
fit_single_k <- function(preprocessed, cfg) {
  fit_warnings <- character(0)
  fit <- withCallingHandlers(
    mgcv::gam(
      y ~ x + s(z, k = cfg$k, bs = cfg$bs),
      family = cfg$family,
      data   = preprocessed,
      method = cfg$smooth_method
    ),
    warning = function(w) {
      fit_warnings[
        length(fit_warnings) + 1L
      ] <<- conditionMessage(w)
      rlang::cnd_muffle(w)
    }
  )

  warning_free <- length(fit_warnings) == 0L
  fit_warnings_ <- if (warning_free) {
    NA_character_
  } else {
    stringr::str_c(
      fit_warnings, collapse = "; "
    )
  }

  gamma_hat <- unname(stats::coef(fit)["x"])
  se_gamma <- summary(
    fit
  )$p.table["x", "Std. Error"]
  fit_converged <- is.finite(gamma_hat) &&
    is.finite(se_gamma)
  gamma_max <- gamma_hat + cfg$z_crit * se_gamma

  list(
    gamma_hat     = gamma_hat,
    se_gamma      = se_gamma,
    gamma_max     = gamma_max,
    fit_converged = fit_converged,
    warning_free  = warning_free,
    fit_warnings  = fit_warnings_,
    model         = fit
  )
}
