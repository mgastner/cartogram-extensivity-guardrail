# test-preprocess.R — tests for the preprocessing layer

# ── Helpers ───────────────────────────────────────────────────────────────────

make_sf <- function(n = 15, y_val = 1, pop_val = 1e5) {
  geoms <- lapply(seq_len(n), function(i) {
    sf::st_polygon(list(matrix(
      c(i, 0, i + 1, 0, i + 1, 1, i, 1, i, 0),
      ncol = 2, byrow = TRUE
    )))
  })
  sf::st_sf(
    y   = rep(y_val, n),
    pop = rep(pop_val, n),
    geometry = sf::st_sfc(geoms, crs = 4326)
  )
}

cfg <- scaling_config()

# ── Valid input ───────────────────────────────────────────────────────────────

test_that("preprocess() returns a tibble for valid sf input", {
  d <- make_sf()
  result <- preprocess(d, "y", "pop", cfg)
  expect_s3_class(result, "tbl_df")
  expect_named(result, c("y", "x", "z", "area_km2", "population"))
  expect_equal(nrow(result), nrow(d))
})

test_that("preprocess() computes finite log predictors", {
  d <- make_sf()
  result <- preprocess(d, "y", "pop", cfg)
  expect_true(all(is.finite(result$x)))
  expect_true(all(is.finite(result$z)))
  expect_true(all(result$area_km2 > 0))
})

# ── sf requirement ────────────────────────────────────────────────────────────

test_that("preprocess() abstains if input is not sf", {
  d <- tibble::tibble(y = 1:15, pop = rep(1e5, 15))
  result <- preprocess(d, "y", "pop", cfg)
  expect_equal(result, "abstain:input_not_sf")
})

# ── Missing columns ───────────────────────────────────────────────────────────

test_that("preprocess() abstains on missing value column", {
  d <- make_sf()
  result <- preprocess(d, "no_such_col", "pop", cfg)
  expect_match(result, "^abstain:missing_columns_")
})

test_that("preprocess() abstains on missing population column", {
  d <- make_sf()
  result <- preprocess(d, "y", "no_such_col", cfg)
  expect_match(result, "^abstain:missing_columns_")
})

# ── Missing / non-finite values are dropped, not fatal ────────────────────────

test_that("preprocess() drops rows with NA in y and continues", {
  d <- make_sf()
  d$y[1] <- NA
  result <- preprocess(d, "y", "pop", cfg)
  # Should succeed as a tibble with one fewer row
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), nrow(d) - 1L)
})

test_that("preprocess() drops rows with Inf in y and continues", {
  d <- make_sf()
  d$y[1] <- Inf
  result <- preprocess(d, "y", "pop", cfg)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), nrow(d) - 1L)
})

test_that("preprocess() drops rows with NA in pop and continues", {
  d <- make_sf()
  d$pop[1] <- NA
  result <- preprocess(d, "y", "pop", cfg)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), nrow(d) - 1L)
})

test_that("preprocess() abstains if all observations are missing", {
  d <- make_sf()
  d$y <- NA_real_
  result <- preprocess(d, "y", "pop", cfg)
  expect_match(result, "^abstain:all_observations_missing")
})

# ── Non-positive values ───────────────────────────────────────────────────────

test_that("preprocess() abstains if y contains a zero", {
  d <- make_sf()
  d$y[1] <- 0
  result <- preprocess(d, "y", "pop", cfg)
  expect_match(result, "^abstain:non_positive_")
})

test_that("preprocess() abstains if y contains a negative value", {
  d <- make_sf()
  d$y[1] <- -1
  result <- preprocess(d, "y", "pop", cfg)
  expect_match(result, "^abstain:non_positive_")
})

test_that("preprocess() abstains if pop contains a zero", {
  d <- make_sf()
  d$pop[1] <- 0
  result <- preprocess(d, "y", "pop", cfg)
  expect_match(result, "^abstain:non_positive_")
})

# ── Missing CRS ───────────────────────────────────────────────────────────────

test_that("preprocess() abstains if CRS is missing", {
  d <- make_sf()
  sf::st_crs(d) <- NA
  result <- preprocess(d, "y", "pop", cfg)
  expect_equal(result, "abstain:missing_crs")
})

# ── Invalid area is dropped gracefully ────────────────────────────────────────

test_that("preprocess() drops regions with zero area and continues", {
  d <- make_sf(n = 15)
  # Replace first geometry with a degenerate line (zero area)
  sf::st_geometry(d)[1] <- sf::st_sfc(
    sf::st_polygon(list(matrix(
      c(0, 0, 0, 0, 0, 0, 0, 0, 0, 0), ncol = 2, byrow = TRUE
    ))),
    crs = 4326
  )
  result <- preprocess(d, "y", "pop", cfg)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 14L)
})

# ── Minimum-n guard ───────────────────────────────────────────────────────────

test_that("preprocess() abstains when n < n_min", {
  d <- make_sf(n = cfg$n_min - 1L)
  result <- preprocess(d, "y", "pop", cfg)
  expect_match(result, "^abstain:too_few_regions_n")
  # Reason code includes both n and n_min
  expect_match(result, "_min")
})

test_that("preprocess() accepts n == n_min", {
  d <- make_sf(n = cfg$n_min)
  result <- preprocess(d, "y", "pop", cfg)
  expect_s3_class(result, "tbl_df")
})
