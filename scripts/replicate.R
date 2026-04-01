# replicate.R — Reproduce all scaling evidence results
#
# Prerequisites:
#   install.packages(c("sf", "mgcv", "tibble", "dplyr", "purrr", "tidyr", "readr", "devtools"))
#
# Usage:
#   setwd("<repo root>")
#   source("scripts/replicate.R")

library(sf)
library(dplyr)
library(readr)

# Load data
boundaries <- st_read("data/world_bank_boundaries_simplified.geojson", quiet = TRUE)
dat <- read_csv("data/admin1_all_variables.csv", show_col_types = FALSE)

# Run all 34 variables
source("scripts/run_all_variables.R")
