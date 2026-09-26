# Embodied emissions in imports (Scope 3 upstream) to the Czech Republic
This repository contains data, scripts and documentation used to estimate greenhouse gas emissions embodied in imports to the Czech Republic.
The resulting Scope 3 upstream emissions estimates are used in my doctoral research examining the relationships among GHG Protocol emission scopes and their determinants.

## Background
The GHG Protocol (2004) distinguishes emissions according to their relationship to the reporting entity: Scope 1 covers direct emissions from sources controlled by the entity; Scope 2 covers indirect emissions from purchased energy; and Scope 3 covers other indirect value chain emissions. 

This project focuses on Scope 3 upstream emissions embodied in imports to the Czech Republic. Emissions are estimated by combining import values from the WITS database with environmentally extended input-output data from EXIOBASE 3.

## Data sources
World Integrated Trade Solution (WITS) database

EXIOBASE

The EXIOBASE data included in the repository were reformatted to improve compatibility with the analysis scripts. No methodological modifications were applied at this stage.

## Workflow
| Step | Description | Script |
|-------|-------------|---------|
| 1 | Import trade data from WITS | `02_trade_data_import.R` |
| 2 | Import EXIOBASE emission factors | `03_emission_factor_prep.R` |
| 3 | Identify and adjust outliers in emission factors | `03_emission_factor_prep.R` |
| 4 | Manually map the HS6 categories used in the WITS database to the EXIOBASE product categories | data/mappings/Top_emission_HS6.xlsx
| 5 | Match emission factors by country and product category | `04_run_analysis.R` |
| 6 | Calculate embodied emissions | `04_run_analysis.R` |
| 7 | Export final results | `04_run_analysis.R` |

For a detailed description of the methodology see:
docs/emissions_methodology.md

## Repository Structure
 
```text
data/
├── raw/
├── mappings/
├── processed/
└── auxiliary/
 
docs/
└── emissions_methodology.md
 
scripts/
├── 00_install_packages.R
├── 01_functions.R
├── 02_trade_data_import.R
├── 03_emission_factor_prep.R
└── 04_run_analysis.R
 
outputs/
├── scope3u_results.xlsx
└── scope3u_emissions/
```

### Main directories
 
- `raw` contains original input datasets.
- `mappings` contains manually created correspondence tables.
- `processed` contains intermediate datasets generated during the workflow.
- `auxiliary` contains supporting files used in the analysis.

## Outputs
 
The analysis produces:
 
- Annual embodied import emissions for the Czech Republic (1995-2023)
- Coverage statistics
- Emission factor adjustment statistics
 

Results are exported to:
 
outputs/scope3u_results.xlsx



## Running the Analysis
 
1. Install required packages:
 
```r
source("scripts/00_install_packages.R")
```
 
2. Run the full workflow:
 
```r
source("scripts/04_run_analysis.R")
```
 
The main script automatically executes all preprocessing and calculation steps.

## Author
 
Martina Smrckova

PhD Candidate in Economics
 
The repository was developed as part of doctoral research on greenhouse gas emissions and their determinants.
