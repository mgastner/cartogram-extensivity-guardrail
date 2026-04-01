# flatten_audit.R — CSV-friendly export of audit results

#' Flatten audit results from an evidence tibble
#'
#' Unnests the `audit_tbl` list-column produced by
#' [extract_scaling_evidence()] into a long-format tibble with one row
#' per variable x audit `k` combination.  This format is useful for
#' saving flat CSV results and for downstream benchmark analysis.
#'
#' @param results A tibble produced by row-binding multiple calls to
#'   [extract_scaling_evidence()], expected to contain at least
#'   `audit_tbl` and any identifying columns (e.g. `variable`,
#'   `country`).
#' @return A tibble with the `audit_tbl` list-column unnested.  Rows
#'   where `audit_tbl` is `NULL` (e.g. early preprocessing abstentions)
#'   are silently dropped.
#' @export
flatten_audit <- function(results) {
  if (!"audit_tbl" %in% names(results)) {
    stop("`results` must contain an `audit_tbl` column.", call. = FALSE)
  }
  # Drop rows where audit_tbl is NULL (preprocessing abstentions)
  has_audit <- purrr::map_lgl(results$audit_tbl, ~ !is.null(.x))
  results <- results[has_audit, ]

  if (nrow(results) == 0L) {
    return(tibble::tibble())
  }

  tidyr::unnest(results, audit_tbl, names_sep = "_")
}

