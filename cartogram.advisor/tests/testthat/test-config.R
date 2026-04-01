test_that("scaling_config() returns a valid config object", {
  cfg <- scaling_config()
  expect_s3_class(cfg, "scaling_config")
  expect_true(cfg$n_min > 0)
  expect_true(length(cfg$k_grid) >= 1)
})

# ── Fixed hyperparameters are present and read-only ──────────────────────────

test_that("config contains fixed hyperparameters as read-only fields", {
  cfg <- scaling_config()
  expect_equal(cfg$alpha, 0.05)
  expect_equal(cfg$z_crit, qnorm(0.95))
  expect_equal(cfg$bs, "tp")
  expect_equal(cfg$smooth_method, "REML")
  expect_true(inherits(cfg$family, "family"))
  expect_equal(cfg$family$family, "Gamma")
  expect_equal(cfg$family$link, "log")
})

# ── Input validation ─────────────────────────────────────────────────────────

test_that("config rejects non-integer n_min", {
  expect_error(scaling_config(n_min = 3.5), "`n_min`")
})

test_that("config rejects n_min < 4", {
  expect_error(scaling_config(n_min = 3L), "`n_min`")
})

test_that("config rejects invalid k_grid", {
  expect_error(scaling_config(k_grid = c(2L, 6L)), "`k_grid`")
  expect_error(scaling_config(k_grid = integer(0)), "`k_grid`")
})

test_that("scaling_config() accepts overrides", {
  cfg <- scaling_config(n_min = 5L, k_grid = c(4L, 8L))
  expect_equal(cfg$n_min, 5L)
  expect_equal(cfg$k_grid, c(4L, 8L))
})

# ── k_grid normalization ────────────────────────────────────────────────────

test_that("config deduplicates and sorts k_grid", {
  cfg <- scaling_config(k_grid = c(8L, 4L, 6L, 4L))
  expect_equal(cfg$k_grid, c(4L, 6L, 8L))
})
