# test-extract_scaling_evidence.R — tests for evidence extraction

# ── Helpers ───────────────────────────────────────────────────────────────────────────

make_sf_realistic <- function(n = 15, seed = 42) {
  set.seed(seed)
  geoms <- lapply(seq_len(n), function(i) {
    sf::st_polygon(list(matrix(
      c(i, 0, i + 1, 0, i + 1, 1, i, 1, i, 0),
      ncol = 2, byrow = TRUE
    )))
  })
  sf::st_sf(
    y   = exp(rnorm(n, mean = 5, sd = 0.5)),
    pop = exp(rnorm(n, mean = 10, sd = 0.3)),
    geometry = sf::st_sfc(geoms, crs = 4326)
  )
}

# ── Basic evidence structure ────────────────────────────────────────────────────────

test_that("extract_scaling_evidence() returns expected structure", {
  d <- make_sf_realistic(n = 15)
  evidence <- extract_scaling_evidence(d, "y", "pop")

  expect_s3_class(evidence, "tbl_df")
  expect_equal(nrow(evidence), 1L)

  # All evidence columns present
  expected_cols <- c("gamma_hat", "se_gamma", "gamma_max", "n_input", "n_used",
                     "n_dropped", "fit_converged", "warning_free", "fit_warnings",
                     "audit_tbl", "reason_code")
  expect_true(all(expected_cols %in% names(evidence)))

  # No decision columns (delta is external)
  expect_false("label" %in% names(evidence))
  expect_false("audit_stable" %in% names(evidence))
})

test_that("extract_scaling_evidence() returns fit_ok reason_code on success", {
  d <- make_sf_realistic(n = 15)
  evidence <- extract_scaling_evidence(d, "y", "pop")

  expect_equal(evidence$reason_code, "fit_ok")
  expect_true(evidence$fit_converged)
})

test_that("extract_scaling_evidence() handles missing population_col", {
  d <- make_sf_realistic(n = 15)
  evidence <- extract_scaling_evidence(d, "y", population_col = NULL)

  expect_equal(evidence$reason_code, "population_col_required")
  expect_true(is.na(evidence$gamma_hat))
})

test_that("extract_scaling_evidence() handles non-sf input", {
  evidence <- extract_scaling_evidence(data = NULL, "y", "pop")

  expect_true(is.na(evidence$gamma_hat))
})

test_that("extract_scaling_evidence() returns audit_tbl as list-column", {
  d <- make_sf_realistic(n = 15)
  evidence <- extract_scaling_evidence(d, "y", "pop")

  expect_type(evidence$audit_tbl, "list")
  audit_tbl <- evidence$audit_tbl[[1]]
  expect_s3_class(audit_tbl, "tbl_df")
  expect_equal(nrow(audit_tbl), 3L)  # default k_grid = c(4, 6, 8)
})

test_that("gamma_max is the maximum across k_grid", {
  d <- make_sf_realistic(n = 15)
  evidence <- extract_scaling_evidence(d, "y", "pop")

  audit_tbl <- evidence$audit_tbl[[1]]
  converged <- audit_tbl[audit_tbl$fit_converged, ]
  expect_equal(evidence$gamma_max, max(converged$gamma_max))
})

