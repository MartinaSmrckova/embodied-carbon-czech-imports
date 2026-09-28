###############################################################################
# Calculation of emissions embodied in Czech imports
#
# This script identifies the most emission-intensive EXIOBASE sectors,
# maps them to HS6 product categories and countries, and calculates
# Scope 3U emissions by year.
#
# The calculation includes all HS6 categories that were in the top N in any year or
# that correspond to the EXIOBASE emission factors that were in top N in any
# year regardless of whether the HS6 category or EF was in the top N in the
# respective year.
#
# Author: Martina Smrckova
# Project: Emissions Embodied in Czech Imports
###############################################################################

## =============================================================================
## 0) Load libraries and run run the preceding scripts
## =============================================================================
library(here)
library(data.table)
library(readxl)
library(writexl)
library(tidyverse)
library(ggplot2)

source(here("scripts", "01_functions.R"))
source(here("scripts", "02_trade_data_import.R"))
source(here("scripts", "03_emission_factor_prep.R"))

## =============================================================================
## 1) User-defined settings
## =============================================================================

## Number of most emission-intensive sectors to retain per year
N_TOP <- 60

## Number of HS6 sectors with the highest trade value to retain per year
HS6_TOP <- 200

## =============================================================================
## 2) Identify the most emission-intensive EXIOBASE sectors
## =============================================================================

# Split adjusted EXIOBASE data by year
exio_factors_adj <- split(
  data.table(exio_factors_plus_outputs_final),
  by = "Year"
)

names(exio_factors_adj) <- paste0("year_", names(exio_factors_adj))

# Containers for results
top_N_ef <- list()
avg_ef_by_sector_list <- list()

for (snapshot in names(exio_factors_adj)) {
  
  df <- exio_factors_adj[[snapshot]]
  
  # Ensure that 'sector' is character (for grepl and printing)
  if (is.factor(df$sector)) df$sector <- as.character(df$sector)
  
  # 1) Remove rows with missing sector or emission factor
  df <- subset(df, !is.na(sector) & !is.na(`EXIOBASE EF`))
  
  # 2) Exclude electricity-related sectors (case-insensitive)
  df <- df[!grepl("electricity", df$sector, ignore.case = TRUE), ]
  
  # Skip year if no data remain
  if (nrow(df) == 0) {
    warning(sprintf("After excluding 'electricity', %s contains no rows.", snapshot))
    next
  }
  
  # 3) Compute average emission factor by sector
  avg_ef_by_sector <- aggregate(
    `EXIOBASE EF` ~ sector,
    data = df,
    FUN = function(x) mean(x, na.rm = TRUE)
  )
  
  avg_ef_by_sector$Year <- ExtractYear(snapshot)
  avg_ef_by_sector_list[[snapshot]] <- avg_ef_by_sector
  
  # 4) Drop sectors outside the analytical scope
  sectors_to_drop <- readLines(
    here("data", "auxiliary", "excluded_exiobase_sectors.txt")
)
  
  avg_ef_by_sector_clean <- avg_ef_by_sector[
    !(avg_ef_by_sector$sector %in% sectors_to_drop),
  ]
  
  # 5) Sort sectors by descending average emission factor
  avg_ef_by_sector_clean <- avg_ef_by_sector_clean[
    order(avg_ef_by_sector_clean$`EXIOBASE EF`, decreasing = TRUE),
  ]
  
  # 6) Select top N sectors (robust to small sample size)
  n_top <- min(N_TOP, nrow(avg_ef_by_sector_clean))
  top_N <- head(avg_ef_by_sector_clean, n_top)
  top_N$Year <- ExtractYear(snapshot)
  
  top_N_ef[[snapshot]] <- top_N
  rownames(top_N_ef[[snapshot]]) <- NULL
}

# Combine top-N sectors across all years
top_N_all <- do.call(rbind, top_N_ef)
rownames(top_N_all) <- NULL

# Identify sectors that appear in the top N in at least one year
unique_sectors <- top_N_all[!duplicated(top_N_all$sector), ]

## =============================================================================
## 3) Identify the HS6 categories with the highest trade value
## =============================================================================

tot_dt_list <- imp_by_year
tot_dt_list <- tot_dt_list[order(as.integer(sub("year_", "", names(tot_dt_list))))]

tot_im_topM <- list()

for (snapshot in names(tot_dt_list)) {
  
  trade_data_year <- copy(tot_dt_list[[snapshot]]) # work with a local copy
  
  # Sort in place (by reference)
  setorder(trade_data_year, -`Trade Value EURm`)
  
  # Keep the top M categories
  trade_data_year <- trade_data_year[1:HS6_TOP]
  
  top_HS6_colname <- paste("Top", HS6_TOP, "HS6", sep = "_")
  trade_data_year[, (top_HS6_colname) := "Yes"]
  
  cols_to_keep <- c("HS6 ID", "HS6", "Year", top_HS6_colname)
  
  # Select columns using the recommended data.table syntax
  trade_data_year <- trade_data_year[, ..cols_to_keep]
  
  tot_im_topM[[snapshot]] <- trade_data_year
}

# Get unique HS6 categories that were in the top M in any year
tot_im_topM_all <- do.call(rbind, tot_im_topM)
unique_HS6 <- tot_im_topM_all[!duplicated(tot_im_topM_all$`HS6 ID`), ]

## =============================================================================
## 4) Load HS6–EXIOBASE mapping
## =============================================================================
path3 <- here("data", "mappings", "HS6_EXIOBASE_mapping.xlsx")
HS6_EXIO_mapping <- read_xlsx(
  path3
)

## =============================================================================
## 5) Map HS6 categories to top EXIOBASE product categories by year
## =============================================================================
unique_HS6$`HS6 ID` <- substr(unique_HS6 $`HS6 ID`,
                              nchar(unique_HS6 $`HS6 ID`) - 5,
                              nchar(unique_HS6 $`HS6 ID`))
HS6_EXIO_mapping$`HS6 ID`<-  as.character(HS6_EXIO_mapping$`HS6 ID`)



filtered_mapping <- HS6_EXIO_mapping[
  HS6_EXIO_mapping$`HS6 ID` %in% unique_HS6$`HS6 ID` |
    HS6_EXIO_mapping$`EXIOBASE EF` %in% unique_sectors$sector,
]

## =============================================================================
## 6) Map EXIOBASE products to HS6 trade data
## =============================================================================

snapshots_products <- list()

for (snapshot in names(imp_by_year)){
  imp_by_year[[snapshot]] <- as.data.table(imp_by_year[[snapshot]])
  filtered_mapping <- as.data.table(filtered_mapping)
  
  imp_by_year[[snapshot]][, `HS6 ID` := Last6DropLeading0(`HS6 ID`)]
  
  snapshots_products[[snapshot]] <- merge(
    imp_by_year[[snapshot]], filtered_mapping,
    by.x = "HS6 ID",
    by.y = "HS6 ID",
  )
  names(snapshots_products[[snapshot]])[names(snapshots_products[[snapshot]]) == "EXIOBASE EF"] <- "EXIOBASE product"
}

## =============================================================================
## 7) Map EXIOBASE countries
## =============================================================================
path4 <- here("data", "mappings", "Countries_mapping.xlsx")
exio_countries <- read_xlsx(
  path4
)

snapshots_countries <- list()

for (snapshot in names(snapshots_products)) {
  snapshots_countries[[snapshot]] <- merge(
    snapshots_products[[snapshot]],
    exio_countries[c("PartnerName", "EXIOBASE_country")],
    by.x = "country_origin",
    by.y = "PartnerName",
    all.x = TRUE
  )
}

## =============================================================================
## 8) Map EXIOBASE emission factors
## =============================================================================

snapshots_emis <- list()

for (snapshot in names(snapshots_countries)) {
  year_n <- ExtractYear(snapshot)
  
  if (year_n > 2022) {
    snapshots_emis[[snapshot]] <- merge(
      snapshots_countries[[snapshot]],
      exio_factors_adj[["year_2022"]],
      by.x = c("EXIOBASE product", "EXIOBASE_country"),
      by.y = c("sector", "region"),
      all.x = TRUE
    )
    
    snapshots_emis[[snapshot]]$Year.y <- NULL
    names(snapshots_emis[[snapshot]])[names(snapshots_emis[[snapshot]]) == "Year.x"] <- "Year"
    
  } else {
    snapshots_emis[[snapshot]] <- merge(
      snapshots_countries[[snapshot]],
      exio_factors_adj[[snapshot]],
      by.x = c("EXIOBASE product", "EXIOBASE_country", "Year"),
      by.y = c("sector", "region", "Year"),
      all.x = TRUE
    )
  }
      
  cols_to_keep <- c(
    "Year", "HS6 ID", "HS6",
    "EXIOBASE product", "country_origin",
    "EXIOBASE_country", "Trade Value EURm",
    "Quantity", "QtyUnit",
    "EXIOBASE EF", "EF_outlier_high", "EF_outlier_low"
  )
  
  # Select columns using data.table syntax
  snapshots_emis[[snapshot]] <- snapshots_emis[[snapshot]][, ..cols_to_keep]
}

## =============================================================================
## 9) Reprice the 2022 EFs used in 2023
## =============================================================================

# Import HICP
path5 <- here("data", "raw", "Inflation", "HICP_EUR.xlsx")

data_HICP <- read_xlsx(
  path5)

HICP <- data.frame(data_HICP$Year, data_HICP$HICP_EUR)
names(HICP) <- c("Year", "HICP")

defl_2022_2023 <- HICP[HICP$Year == 2023,]$HICP / HICP[HICP$Year == 2022,]$HICP

snapshots_emis[["year_2023"]]$`EXIOBASE EF` <- 
  snapshots_emis[["year_2023"]]$`EXIOBASE EF` / defl_2022_2023

## =============================================================================
## 10) Calculate Scope 3U emissions by product and country
## =============================================================================

for (snapshot in names(snapshots_emis)) {
  snapshots_emis[[snapshot]]$Scope3U_Mt_CO2e <-
    (snapshots_emis[[snapshot]]$`Trade Value EURm` *
       snapshots_emis[[snapshot]]$`EXIOBASE EF`) / 1e9
  
  snapshots_emis[[snapshot]]$Scope3U_SUM <- sum(
    snapshots_emis[[snapshot]]$Scope3U_Mt_CO2e[!is.na(snapshots_emis[[snapshot]]$Scope3U_Mt_CO2e)])
  snapshots_emis[[snapshot]]$Scope3U_pct <- 
    snapshots_emis[[snapshot]]$Scope3U_Mt_CO2e / snapshots_emis[[snapshot]]$Scope3U_SUM
  
  snapshots_emis[[snapshot]]$Scope3U_SUM <- NULL
}

## =============================================================================
## 11) Calculate total Scope 3U emissions by year
## =============================================================================

scope3u_Mt_CO2e <- numeric(length(snapshots_emis))

for (i in seq_along(snapshots_emis)) {
  scope3u_Mt_CO2e[i] <- sum(snapshots_emis[[i]]$Scope3U_Mt_CO2e, na.rm = TRUE)
}

scope3u_Mt_CO2e_year <- data.frame(
  Year = seq(1995, 2023),
  Scope3U_Mt_CO2e = scope3u_Mt_CO2e
)

## =============================================================================
## 12) Calculate import coverage for each year
## =============================================================================

im_covered <- list()

for (snapshot in names(snapshots_emis)) {
  im_covered[[snapshot]] <- sum(snapshots_emis[[snapshot]]$`Trade Value EURm`)
}

im_total <- list()
coverage_shares <- list()

for (snapshot in names(imp_by_year)) {
  im_total[[snapshot]] <- sum(imp_by_year[[snapshot]]$`Trade Value EURm`)
  coverage_shares[[snapshot]] <- im_covered[[snapshot]] / im_total[[snapshot]]
}

## =============================================================================
## 13) Calculate the imputation statistics
## =============================================================================
snapshots_emis_df <- do.call(rbind, snapshots_emis)

unique_EF <- unique(snapshots_emis_df[, c("EXIOBASE product", "EXIOBASE_country")])
unique_EF$EF_name <- paste(unique_EF$EXIOBASE_country, unique_EF$`EXIOBASE product`, sep = ".")

# Calculate number of unique EF used in the emission estimation
unique_EF_num <- nrow(unique_EF)

# Calculate number of emission factors that were outlier-adjusted
one_out_EF_num     <- intersect(names(EF_outliers_1), unique_EF$EF_name)
two_six_out_EF_num <- intersect(names(EF_outliers_2_6), unique_EF$EF_name) 
more_out_EF_num    <- intersect(names(EF_outliers_more), unique_EF$EF_name)

one_out_EF_norm_num     <- intersect(one_out_EF_num, names(EF_normal))
one_out_EF_non_norm_num <- intersect(one_out_EF_num, names(EF_non_normal))

two_six_out_EF_norm_num     <- intersect(two_six_out_EF_num, names(EF_normal))
two_six_out_EF_non_norm_num <- intersect(two_six_out_EF_num, names(EF_non_normal))

more_out_EF_norm_num     <- intersect(more_out_EF_num, names(EF_normal))
more_out_EF_non_norm_num <- intersect(more_out_EF_num, names(EF_non_normal))

# Calculate number of negative emission factors
neg_EF_num <- intersect(names(EF_negative), unique_EF$EF_name)

# Calculate number of zero emission factors
zero_EF_num <- intersect(names(zero_EF), unique_EF$EF_name)

# Calculate total adjusted EFs
total_adj <- unique(c(one_out_EF_num, two_six_out_EF_num, more_out_EF_num,
               neg_EF_num, zero_EF_num))


stats <- data.frame(name = c("Used EFs total",
                             "Used EF with outliers",
                             "Of which: EFs with 1 outlier",
                             "Of which: EFs with 2-6 outliers",
                             "Of which: Used EFs with > 6 outliers",
                             "Used negative adjusted outliers",
                             "Used zero adjusted EFs",
                             "Total adjusted EFs"),
                    value = c(nrow(unique_EF),
                              length(one_out_EF_num) + length(two_six_out_EF_num) + length(more_out_EF_num),
                              length(one_out_EF_num),
                              length(two_six_out_EF_num),
                              length(more_out_EF_num),
                              length(neg_EF_num),
                              length(zero_EF_num),
                              length(total_adj)))

stats$pct <- stats$value / stats$value[1]
stats$pct <- paste(round(stats$pct * 100, 2), "%", sep = "")

## =============================================================================
## 14) Give the message that the Scope 3U emissions ran succesfully
## =============================================================================
message(
  cat(
    "Total Scope 3U emissions in 2023:",
    scope3u_Mt_CO2e_year$Scope3U_Mt_CO2e[
      scope3u_Mt_CO2e_year$Year == 2023
    ]
  )
)

## =============================================================================
## 15) Export the results
## =============================================================================
results <- list(
  scope3u_emissions = scope3u_Mt_CO2e_year,
  coverage = data.frame(
    Year = 1995:2023,
    Coverage = unlist(coverage_shares)
  ),
  ef_statistics = stats
)

write_xlsx(
  results,
  here("outputs", "scope3u_results.xlsx")
)

## =============================================================================
## 16) Generate graph with resulting emissions
## =============================================================================
ggplot(
  scope3u_Mt_CO2e_year,
  aes(x = Year, y = Scope3U_Mt_CO2e)
) +
  geom_line(
    colour = "#2C7FB8",
    linewidth = 1.2
  ) +
  geom_point(
    colour = "#2C7FB8",
    size = 1.8
  ) +
  labs(
    title = "Scope 3 Upstream Emissions Associated with Czech Imports",
    subtitle = "Estimated using EXIOBASE emission factors and WITS trade data",
    x = "Year",
    y = "Scope 3 upstream emissions (Mt CO2e)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(
      face = "bold",
      size = 14
    ),
    plot.subtitle = element_text(
      size = 11
    ),
    axis.title = element_text(
      face = "bold"
    ),
    panel.grid.minor = element_blank()
  )

ggsave(
  here("outputs", "scope3u_emissions.png"),
  width = 8,
  height = 5
)
