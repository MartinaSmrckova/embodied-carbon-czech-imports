# Embodied emissions in imports (Scope 3 upstream) to the Czech Republic
This repository contains scripts and data used to estimate greenhouse gas emissions embodied in imports to the Czech Republic. The calculated emissions are used for my research estimating relationships among emission scopes as defined by the GHG Protocol and their determinants.

## Data sources
World Integrated Trade Solution (WITS) database
EXIOBASE

## Workflow
Import raw trade data
Import EXIOBASE emission factors
Adjust for outliers in the emission factors
Manually match HS6 categories to EXIOBASE product categories
Match emission factors by country and product type
Calculate embodied emissions

For a detailed description of the methodology see:
docs/emissions_methodology.md
