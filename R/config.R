# config.R — scaling test configuration object

# ── Fixed hyperparameters (single source of truth) ────────
# These values were chosen by exploratory data analysis
# and are not exposed as user-facing parameters.
# All modelling code reads them from the config object
# rather than hard-coding values, ensuring a single
# source of truth.

.FIXED_ALPHA         <- 0.05
.FIXED_Z_CRIT        <- stats::qnorm(1 - .FIXED_ALPHA)
.FIXED_FAMILY        <- stats::Gamma(link = "log")
.FIXED_BS            <- "tp"
.FIXED_SMOOTH_METHOD <- "REML"

# Create a scaling test configuration object
#
# Returns a configuration object containing the
# hyperparameters for the area-scaling GAM.  The object
# controls data-quality filters and the spline basis
# dimensions used in the sensitivity sweep.
scaling_config <- function(
    n_min  = 10L,
    k_grid = c(4L, 6L, 8L)
) {
  # ── Input validation ──────────────────────────────────
  if (!is.numeric(n_min) || length(n_min) != 1 ||
      n_min < 4 || n_min != as.integer(n_min)) {
    cli::cli_abort(
      "{.arg n_min} must be a single integer >= 4."
    )
  }
  if (!is.numeric(k_grid) || length(k_grid) < 1 ||
      any(k_grid < 3) ||
      !all(k_grid == as.integer(k_grid))) {
    cli::cli_abort(
      "{.arg k_grid} must be an integer vector >= 3."
    )
  }

  # Normalize: deduplicate and sort
  k_grid <- sort(unique(as.integer(k_grid)))

  cfg <- list(
    n_min         = as.integer(n_min),
    k_grid        = k_grid,
    alpha         = .FIXED_ALPHA,
    z_crit        = .FIXED_Z_CRIT,
    family        = .FIXED_FAMILY,
    bs            = .FIXED_BS,
    smooth_method = .FIXED_SMOOTH_METHOD
  )
  structure(cfg, class = "scaling_config")
}
