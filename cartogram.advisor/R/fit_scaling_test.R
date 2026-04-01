# fit_scaling_test.R — one-sided area-scaling test

#' Fit the unrestricted GAM for the area-scaling test
#'
#' Fits the generalised model
#' \deqn{M_g:\quad \log \mu_i = a + \gamma x_i + s(z_i)}
#' using the family, basis type, and smoothing method stored in
#' `cfg` (fixed by EDA; see [scaling_config()]).
#'
#' Computes a one-sided upper confidence bound
#' \deqn{\gamma_{\max} = \hat\gamma + z_{\mathrm{crit}}\,
#'   \mathrm{SE}(\hat\gamma).}
#'
#' This function does not apply any decision threshold (delta).
#'
#' @param preprocessed A tibble returned by [preprocess()].
#' @param cfg A `scaling_config` object.
#' @return A named list with components:
#'   \describe{
#'     \item{`gamma_hat`}{Point estimate of \eqn{\gamma}.}
#'     \item{`se_gamma`}{Standard error of \eqn{\hat\gamma}.}
#'     \item{`gamma_max`}{One-sided upper confidence bound.}
#'     \item{`fit_converged`}{Logical; `TRUE` if the GAM produced
#'       finite coefficient estimates (i.e. the fit is usable).}
#'     \item{`warning_free`}{Logical; `TRUE` if the GAM converged
#'       without any warnings.}
#'     \item{`fit_warnings`}{Character or `NA_character_`; semicolon-
#'       separated warning messages, if any.}
#'     \item{`model`}{The fitted `gam` object (or `NULL` on failure).}
#'   }
#' @keywords internal
fit_scaling_test <- function(preprocessed, cfg) {

  # ── Fit the unrestricted GAM, capturing all warnings ─────────────────────
  fit_warnings <- character(0)
  fit <- withCallingHandlers(
    mgcv::gam(
      y ~ x + s(z, k = cfg$k, bs = cfg$bs),
      family = cfg$family,
      data   = preprocessed,
      method = cfg$smooth_method
    ),
    warning = function(w) {
      fit_warnings[[length(fit_warnings) + 1L]] <<- conditionMessage(w)
      invokeRestart("muffleWarning")
    }
  )

  warning_free <- length(fit_warnings) == 0L
  fit_warnings_ <- if (warning_free) NA_character_ else paste(fit_warnings, collapse = "; ")

  # ── Extract gamma estimate and one-sided upper bound ────────────────────
  gamma_hat <- unname(stats::coef(fit)["x"])
  se_gamma  <- summary(fit)$p.table["x", "Std. Error"]
  fit_converged <- is.finite(gamma_hat) && is.finite(se_gamma)

  gamma_max <- gamma_hat + cfg$z_crit * se_gamma

  # NOTE: No label computation here — that's delta-dependent and happens later

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
