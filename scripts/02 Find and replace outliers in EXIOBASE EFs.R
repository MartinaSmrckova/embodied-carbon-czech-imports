###############################################################################
# This script finds outliers in EXIOBASE emission factors and replaces them.
###############################################################################

# -----------------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------------
library(here)
library(dplyr)
library(readxl)
library(stringr)
library(writexl)
library(data.table)
library(tseries)

source(here("scripts", "00 Functions.R"))

## =============================================================================
## 0) Outlier detection settings (user-adjustable)
## =============================================================================

# Jarque-bera test significance
a_jb <- 0.05


## =============================================================================
## 1) Import EXIOBASE emission factors and outputs
## =============================================================================
# Note:
# - The S tables must be converted to .xlsx and transposed beforehand
# - Expected columns: region, sector, GHG emissions

# Root folder containing IOT_1995_pxp, IOT_1996_pxp, ... directories
root_dir <- here("data", "raw", "Exiobase emission factors")

# Pattern for IOT folders (IOT_YYYY_pxp)
dir_regex <- "^IOT_\\d{4}_pxp$"


# ---- Discover IOT folders ----------------------------------------------------

# List immediate subdirectories of root_dir
all_children <- list.dirs(root_dir, recursive = FALSE, full.names = TRUE)

# Keep only directories matching the IOT_YYYY_pxp pattern
iot_dirs <- all_children[grepl(dir_regex, basename(all_children))]

# Stop if no matching folders are found
if (length(iot_dirs) == 0L) {
  stop("No folders matching 'IOT_YYYY_pxp' found under: ", root_dir)
}


# ---- Build paths to impacts/S.xlsx -------------------------------------------

# Construct paths: <root>/IOT_YYYY_pxp/impacts/S.xlsx
s_paths <- file.path(iot_dirs, "impacts", "S.xlsx")

# Keep only existing files
s_paths_exist <- s_paths[file.exists(s_paths)]

# Report missing files
if (length(s_paths_exist) == 0L) {
  stop("No 'impacts/S.xlsx' files were found in the matched folders.")
} else if (length(s_paths_exist) < length(s_paths)) {
  missing <- setdiff(s_paths, s_paths_exist)
  warning(
    "Some 'impacts/S.xlsx' files are missing:\n",
    paste0(" - ", missing, collapse = "\n")
  )
}

# Extract years from folder names
years <- str_extract(iot_dirs, "\\d{4}_pxp")
years <- substr(years, 1, 4)

# Read emission factors
exio_factors <- list()

for (i in seq_along(s_paths_exist)) {
  df <- read_xlsx(s_paths_exist[i])
  names(df)[3] <- "EXIOBASE EF"
  df$Year <- as.numeric(years[i])
  exio_factors[[i]] <- df
}

names(exio_factors) <- paste0("year_", years)


# ---- Build paths to x.xlsx (outputs) -----------------------------------------

# Construct paths: <root>/IOT_YYYY_pxp/x.xlsx
x_paths <- file.path(iot_dirs, "x.xlsx")

# Keep only existing files
x_paths_exist <- x_paths[file.exists(x_paths)]

# Report missing files
if (length(x_paths_exist) == 0L) {
  stop("No 'x.xlsx' files were found in the matched folders.")
} else if (length(x_paths_exist) < length(x_paths)) {
  missing <- setdiff(x_paths, x_paths_exist)
  warning(
    "Some 'x.xlsx' files are missing:\n",
    paste0(" - ", missing, collapse = "\n")
  )
}

# Read outputs
exio_outputs <- list()

for (i in seq_along(x_paths_exist)) {
  df <- read_xlsx(x_paths_exist[i])
  names(df)[3] <- "EXIOBASE_OUT"
  exio_outputs[[i]] <- df
}

names(exio_outputs) <- names(exio_factors)


## =============================================================================
## 2) Merge emission factors and outputs
## =============================================================================

# Add year information to outputs
for (snapshot in names(exio_outputs)) {
  exio_outputs[[snapshot]]$Year <- as.numeric(substr(snapshot, 6, 9))
}

# Combine all years
exio_outputs_all <- do.call(rbind, exio_outputs)
exio_factors_all <- do.call(rbind, exio_factors)

# Merge EF and output data
exio_factors_plus_outputs <- merge(
  exio_factors_all,
  exio_outputs_all,
  by = c("region", "sector", "Year")
)

# Save merged dataset
path2 <- here("data", "processed", "EXIO_factors_outputs.xlsx")
write_xlsx(
  exio_factors_plus_outputs,
  path2
)

# Split into time series by region–sector combination
exio_factors_plus_outputs_list <- split(
  exio_factors_plus_outputs,
  list(
    exio_factors_plus_outputs$region,
    exio_factors_plus_outputs$sector
  ),
  drop = TRUE
)

## =============================================================================
## 3) Test normality of EF and output series
## =============================================================================

EF_normal <- list()
EF_non_normal <- list()
EF_NA <- list()

for (series in names(exio_factors_plus_outputs_list)) {
  df <- exio_factors_plus_outputs_list[[series]]
  
  df <- DetectNormality(df = df,
                        var = "EXIOBASE EF",
                        jb_thresh = a_jb,
                        norm_name = "EF_normal")
  
  df <- DetectNormality(df = df,
                        var = "EXIOBASE_OUT",
                        jb_thresh = a_jb,
                        norm_name = "OUT_normal") 
  
  exio_factors_plus_outputs_list[[series]] <- df
  
  if (is.na(exio_factors_plus_outputs_list[[series]]$EF_normal[1])){
    EF_NA[[series]] <- exio_factors_plus_outputs_list[[series]]
  } else if (exio_factors_plus_outputs_list[[series]]$EF_normal[1] == "Yes"){
    EF_normal[[series]] <- exio_factors_plus_outputs_list[[series]]
  } else {
    EF_non_normal[[series]] <- exio_factors_plus_outputs_list[[series]]
  }
  
}

## =============================================================================
## 4) Detect outliers
## =============================================================================

EF_outliers_0 <- list()
EF_outliers_1 <- list()
EF_outliers_2_6 <- list()
EF_outliers_more <- list()

# For normal time series, use the Z-score based detection algorithm
# For non-normal time series, use the IQR based detection algorithm

for (series in names(exio_factors_plus_outputs_list)) {
  df <- exio_factors_plus_outputs_list[[series]]
  
  if (is.na(df$EF_normal[1])){
    df <- df
  } else if (df$EF_normal[1] == "Yes"){
    df <- ZScoreOutliers(df = df, var = "EXIOBASE EF")
  } else {
    df <- IQROutliers(df = df, var = "EXIOBASE EF")
  }
  
  if (is.na(df$OUT_normal[1])){
    df <- df
  } else if (df$OUT_normal[1] == "Yes"){
    df <- ZScoreOutliers(df = df, var = "EXIOBASE_OUT")
  } else {
    df <- IQROutliers(df = df, var = "EXIOBASE_OUT")
  }
   
  outl_len <- nrow(df[df$EF_outlier_low == "Yes" | df$EF_outlier_high == "Yes",])
  
  if (outl_len == 0){
    EF_outliers_0[[series]] <- df
  } else if (outl_len == 1){
    EF_outliers_1[[series]] <- df
  } else if (outl_len <= 6){
    EF_outliers_2_6[[series]] <- df
  } else {
    EF_outliers_more[[series]] <- df
  }

  exio_factors_plus_outputs_list[[series]] <- df
  exio_factors_plus_outputs_list[[series]]$EF_normal <- NULL
  exio_factors_plus_outputs_list[[series]]$OUT_normal <- NULL
}

## =============================================================================
## 5) Imputate the outliers
## =============================================================================

exio_factors_plus_outputs_list_adj <- exio_factors_plus_outputs_list

# Series with only one outlier
for (series in names(EF_outliers_1)) {
  EF_outliers_1[[series]] <- OutlierImputate(m = "ent_DF",
                                             EF_outliers_1[[series]],
                                             var = "EXIOBASE EF",
                                             out_high = "EF_outlier_high",
                                             out_low = "EF_outlier_low")
  
  exio_factors_plus_outputs_list_adj[[series]] <- EF_outliers_1[[series]]
}

# Series with 2-6 outliers
for (series in names(EF_outliers_2_6)) {
  df <- EF_outliers_2_6[[series]]
  
  out_num_0 <- which(df$EF_outlier_high == "Yes" | df$EF_outlier_low == "Yes")
  out_num_1 <- which(df$EF_outlier_high == "Yes")
  out_num_2 <- which(df$EF_outlier_low == "Yes")
  isolated_outliers <- IsolatedOutliers(out_num_0)

    # If all EF outliers are also output outliers imputate all outliers
  if (all(df[out_num_1, ]$OUT_outlier_low == "Yes") & all(df[out_num_2, ]$OUT_outlier_high == "Yes")) {
    df <- OutlierImputate(m = "ef_and_out",
                          EF_outliers_2_6[[series]],
                          var = "EXIOBASE EF",
                          out_high = "EF_outlier_high",
                          out_low = "EF_outlier_low")
  } else if (length(isolated_outliers) > 0){
    df <- OutlierImputate(m = "isolated_only",
                          EF_outliers_2_6[[series]],
                          var = "EXIOBASE EF",
                          out_high = "EF_outlier_high",
                          out_low = "EF_outlier_low")
  } else {
    df <- df
  }
  
  exio_factors_plus_outputs_list_adj[[series]] <- df
  
  EF_outliers_2_6[[series]] <- df
}

# Series with more than 6 outliers
for (series in names(EF_outliers_more)) {
  df <- EF_outliers_more[[series]]
  
  out_num_0 <- which(df$EF_outlier_high == "Yes" | df$EF_outlier_low == "Yes")
  out_num_1 <- which(df$EF_outlier_high == "Yes")
  out_num_2 <- which(df$EF_outlier_low == "Yes")
  isolated_outliers <- IsolatedOutliers(out_num_0)
  
  if (length(isolated_outliers) > 0){
    df <- OutlierImputate(m = "isolated_only",
                          EF_outliers_more[[series]],
                          var = "EXIOBASE EF",
                          out_high = "EF_outlier_high",
                          out_low = "EF_outlier_low")
  } else {
    df <- df
  }
   
  exio_factors_plus_outputs_list_adj[[series]] <- df
  EF_outliers_more[[series]] <- df
}

## =============================================================================
## 5) Imputate negative emission factors
## =============================================================================
EF_negative <- list()
EF_no_negative <- list()
exio_factors_plus_outputs_list_adj2 <- exio_factors_plus_outputs_list_adj

for (series in names(exio_factors_plus_outputs_list_adj)) {
  if (any(exio_factors_plus_outputs_list_adj[[series]]$`EXIOBASE EF` < 0)){
    EF_negative[[series]] <- exio_factors_plus_outputs_list_adj[[series]]
  } else {
    EF_no_negative[[series]] <- exio_factors_plus_outputs_list_adj[[series]]
  }
}

for (series in names(EF_negative)) {
  for (i in 1:nrow(EF_negative[[series]])) {
    EF_negative[[series]]$Neg_EF[i] <- ifelse(EF_negative[[series]]$`EXIOBASE EF`[i] < 0,
                                              "Yes", "No")
  }
}

for (series in names(EF_negative)) {
  df <- EF_negative[[series]]
  avg_pos <- mean(df$`EXIOBASE EF`[df$`EXIOBASE EF` >= 0])

  for (i in 1:nrow(df)) {
    df$`EXIOBASE EF`[i] <- ifelse(df$Neg_EF[i] == "Yes",
                                  avg_pos,
                                  df$`EXIOBASE EF`[i])
  } 
  
  df$Neg_EF <- NULL
  EF_negative[[series]] <- df
  exio_factors_plus_outputs_list_adj2[[series]] <- EF_negative[[series]]
}

## =============================================================================
## 6) Imputate zero emission factors
## =============================================================================

## Calculate the sector-year averages
# Divide the exio_factors_plus_outputs_adj2 dataset by sector and year
exio_factors_plus_outputs_adj2 <- rbindlist(exio_factors_plus_outputs_list_adj2, fill = TRUE)


exio_factors_plus_outputs_list_adj3 <- split(
  exio_factors_plus_outputs_adj2,
  interaction(exio_factors_plus_outputs_adj2$sector, exio_factors_plus_outputs_adj2$Year, drop = TRUE, sep = "__"),
  drop = TRUE
)

avg_ef_sector_year_lst <- list()

for (sector in names(exio_factors_plus_outputs_list_adj3)) {
  exio_factors_plus_outputs_list_adj3[[sector]]$Emissions <-
    exio_factors_plus_outputs_list_adj3[[sector]]$`EXIOBASE EF` * 
    exio_factors_plus_outputs_list_adj3[[sector]]$EXIOBASE_OUT
  avg_ef_sector_year_lst[[sector]] <-
    sum(exio_factors_plus_outputs_list_adj3[[sector]]$Emissions) / 
    sum(exio_factors_plus_outputs_list_adj3[[sector]]$EXIOBASE_OUT)
}


avg_ef_sector_year <- unlist(avg_ef_sector_year_lst, use.names = TRUE)

avg_ef_sector_year <- data.frame(
  sector_year = names(avg_ef_sector_year),
  avg_EF = as.numeric(avg_ef_sector_year),
  row.names = NULL
)

# nahradit NaN za NA (volitelně)
avg_ef_sector_year$avg_EF[is.nan(avg_ef_sector_year$avg_EF)] <- NA_real_

avg_ef_sector_year$sector <- sub("__.*$", "", avg_ef_sector_year$sector_year)
avg_ef_sector_year$Year   <- as.numeric(sub("^.*__", "", avg_ef_sector_year$sector_year))
avg_ef_sector_year$sector_year <- NULL
avg_ef_sector_year <- avg_ef_sector_year[c("sector", "Year", "avg_EF")]

# Connect the EFs to the respective averages
exio_factors_plus_outputs_adj3 <- merge(exio_factors_plus_outputs_adj2,
                                        avg_ef_sector_year,
                                        by = c("sector", "Year"))

# Replace the zero emission factors corresponding to zero outputs with avg_EFs
exio_factors_plus_outputs_list_adj3 <- split(
  data.table(exio_factors_plus_outputs_adj3),
  list(exio_factors_plus_outputs_adj3$region, exio_factors_plus_outputs_adj3$sector),
  drop = TRUE
)

zero_EF <- list()

for (series in names(exio_factors_plus_outputs_list_adj3)) {
  df <- exio_factors_plus_outputs_list_adj3[[series]]
  
  
  if (any(df$`EXIOBASE EF` == 0 & df$EXIOBASE_OUT == 0, na.rm = TRUE)
  ) {
    zero_EF[[series]] <- df
  }
  
  exio_factors_plus_outputs_list_adj3[[series]] <- df
}

for (series in names(zero_EF)) {
  
  for (i in 1:nrow(zero_EF[[series]])) {
    if (zero_EF[[series]]$`EXIOBASE EF`[i] == 0 &
        zero_EF[[series]]$EXIOBASE_OUT[i] == 0){
      zero_EF[[series]]$`EXIOBASE EF`[i] <- zero_EF[[series]]$avg_EF[i]
    } else if (zero_EF[[series]]$`EXIOBASE EF`[i] == 0){
      zero_EF[[series]]$`EXIOBASE EF`[i] <- zero_EF[[series]]$avg_EF[i]
    } else {
      zero_EF[[series]]$`EXIOBASE EF`[i] <- zero_EF[[series]]$`EXIOBASE EF`[i]
    }
  }
  
  exio_factors_plus_outputs_list_adj3[[series]] <- zero_EF[[series]]
}

exio_factors_plus_outputs_final <- do.call(rbind, exio_factors_plus_outputs_list_adj3)
exio_factors_plus_outputs_final$avg_EF <- NULL
exio_factors_plus_outputs_final$EF_normal <- NULL
exio_factors_plus_outputs_final$OUT_normal <- NULL
exio_factors_plus_outputs_final$IS_outlier <- NULL

exio_factors_plus_outputs_list_final <- split(exio_factors_plus_outputs_final,
                                              list(exio_factors_plus_outputs_final$region, exio_factors_plus_outputs_final$sector),
                                              drop = TRUE) 


