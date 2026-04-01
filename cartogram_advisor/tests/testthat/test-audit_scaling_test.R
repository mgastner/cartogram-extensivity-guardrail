# test-audit_scaling_test.R — tests for the sensitivity audit

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

cfg <- scaling_config()

# ── Basic audit structure ────────────────────────────────────────────────────────────

test_that("audit_scaling_test() returns tibble with expected columns", {
  d <- make_sf_realistic(n = 15)
  preprocessed <- preprocess(d, "y", "pop", cfg)
  audit_tbl <- audit_scaling_test(preprocessed, cfg)

  expect_s3_class(audit_tbl, "tbl_df")
  expect_equal(nrow(audit_tbl), length(cfg$k_grid))
  expect_true(all(c("k", "gamma_hat", "se_gamma", "gamma_max",
                     "fit_converged", "warning_free", "fit_warnings") %in%
                    names(audit_tbl)))
  # No decision columns
  expect_false("label" %in% names(audit_tbl))
})

test_that("audit fits all k values in k_grid", {
  d <- make_sf_realistic(n = 15)
  preprocessed <- preprocess(d, "y", "pop", cfg)
  audit_tbl <- audit_scaling_test(preprocessed, cfg)

  expect_equal(sort(audit_tbl$k), sort(cfg$k_grid))
})

test_that("audit with custom k_grid works", {
  cfg_alt <- scaling_config(k_grid = c(4L, 8L))
  d <- make_sf_realistic(n = 15)
  preprocessed <- preprocess(d, "y", "pop", cfg_alt)
  audit_tbl <- audit_scaling_test(preprocessed, cfg_alt)

  expect_equal(nrow(audit_tbl), 2L)
  expect_equal(sort(audit_tbl$k), c(4L, 8L))
})

test_that("audit results are reproducible", {
  d <- make_sf_realistic(n = 15)
  preprocessed <- preprocess(d, "y", "pop", cfg)

  audit_1 <- audit_scaling_test(preprocessed, cfg)
  audit_2 <- audit_scaling_test(preprocessed, cfg)

  expect_equal(audit_1$gamma_hat, audit_2$gamma_hat, tolerance = 1e-10)
  expect_equal(audit_1$gamma_max, audit_2$gamma_max, tolerance = 1e-10)
})

