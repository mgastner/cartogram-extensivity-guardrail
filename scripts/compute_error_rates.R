# compute_error_rates.R — ROC-AUC, false-alarm
# and miss rates from cached result CSVs
#
# Run after fit_all_variables.R has populated
# results/.
#
# Usage:
#   Rscript scripts/compute_error_rates.R

# Source analysis functions
r_files <- sort(fs::dir_ls("R", glob = "*.R"))
purrr::walk(r_files, source)

# Read and aggregate results
evidence <- read_all_evidence()

# ROC-AUC
auc <- roc_auc(evidence)
cli::cli_alert_info("ROC-AUC: {round(auc, 4)}")

# Error rates across a range of delta values
deltas <- seq(0, 0.5, by = 0.05)
rates <- purrr::map_dfr(
  deltas, \(d) error_rates(evidence, d)
)

print(rates, n = Inf)
