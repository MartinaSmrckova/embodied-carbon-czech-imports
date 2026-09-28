###############################################################################
# Install Required Packages
#
# This script installs all R packages required to reproduce the analysis
# presented in this repository.
#
# Users only need to run this script once before executing the main workflow.
#
# Author: Martina Smrckova
# Project: Emissions Embodied in Czech Imports
###############################################################################

# List of required packages
required_packages <- c(
  "here",
  "dplyr",
  "data.table",
  "writexl",
  "tidverse",
  "readr",
  "readxl",
  "openxlsx",
  "ggplot2",
  "stringr",
  "tidyr",
  "tseries",
  "purrr"
)

# Identify packages that are not yet installed
missing_packages <- required_packages[
  !(required_packages %in% installed.packages()[,"Package"])
]

# Install missing packages
if(length(missing_packages) > 0){
  stop(
    paste(
      "Missing packages:",
      paste(missing_packages, collapse = ", ")
    )
  )
}
