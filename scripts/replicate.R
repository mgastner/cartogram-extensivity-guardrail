# replicate.R — Reproduce all scaling evidence results
#
# Prerequisites:
#   install.packages(c(
#     "mgcv", "tibble", "dplyr",
#     "purrr", "tidyr", "readr"
#   ))
#
# Usage:
#   setwd("<repo root>")
#   source("scripts/replicate.R")

library(dplyr)
library(readr)

# Source analysis functions
r_files <- sort(fs::dir_ls("R", glob = "*.R"))
purrr::walk(r_files, source)
source("scripts/run_all_countries.R")

# Load data
dat <- read_csv(
  "data/admin1_all_variables.csv",
  show_col_types = FALSE
)

# Run all 34 variables
source("scripts/run_all_variables.R")
