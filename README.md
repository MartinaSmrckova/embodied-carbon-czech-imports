# Embodied emissions in imports (Scope 3 upstream) to the Czech Republic
This repository contains scripts and data used to estimate greenhouse gas emissions embodied in imports to the Czech Republic. The calculated emissions are used for my research estimating relationships among emission scopes as defined by the GHG Protocol and their determinants.

## Data sources
World Integrated Trade Solution (WITS) database
EXIOBASE

## Workflow
1. Import raw trade data
2. Import EXIOBASE emission factors
3. Adjust for outliers in the emission factors
4. Manually match HS6 categories to EXIOBASE product categories
5. Match emission factors by country and product type
6. Calculate embodied emissions

For a detailed description of the methodology see:
docs/emissions_methodology.md
