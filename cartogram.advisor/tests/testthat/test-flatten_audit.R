# test-flatten_audit.R — tests for the CSV-friendly export helper

test_that("flatten_audit() unnests audit_tbl into long format", {
  audit_tbl_inner <- tibble::tibble(
    k             = c(4L, 6L, 8L),
    gamma_hat     = c(0.5, 0.6, 0.7),
    se_gamma      = c(0.1, 0.1, 0.1),
    gamma_max     = c(0.6, 0.7, 0.8),
    fit_converged = c(TRUE, TRUE, TRUE),
    warning_free  = c(TRUE, TRUE, TRUE),
    fit_warnings   = rep(NA_character_, 3)
  )
  results <- tibble::tibble(
    variable  = "gdp",
    audit_tbl = list(audit_tbl_inner)
  )

  flat <- flatten_audit(results)
  expect_s3_class(flat, "tbl_df")
  expect_equal(nrow(flat), 3L)
  expect_true("audit_tbl_k" %in% names(flat))
  expect_true("variable" %in% names(flat))
})

test_that("flatten_audit() drops rows with NULL audit_tbl", {
  results <- tibble::tibble(
    variable  = c("gdp", "precip"),
    audit_tbl = list(
      tibble::tibble(k = 6L, gamma_hat = 0.5, se_gamma = 0.1,
                     gamma_max = 0.6,
                     fit_converged = TRUE, warning_free = TRUE,
                     fit_warnings = NA_character_),
      NULL
    )
  )

  flat <- flatten_audit(results)
  expect_equal(nrow(flat), 1L)
  expect_equal(flat$variable, "gdp")
})

test_that("flatten_audit() returns empty tibble when all audit_tbl are NULL", {
  results <- tibble::tibble(
    variable  = "gdp",
    audit_tbl = list(NULL)
  )

  flat <- flatten_audit(results)
  expect_equal(nrow(flat), 0L)
})

test_that("flatten_audit() errors on missing audit_tbl column", {
  results <- tibble::tibble(variable = "gdp")
  expect_error(flatten_audit(results), "audit_tbl")
})

