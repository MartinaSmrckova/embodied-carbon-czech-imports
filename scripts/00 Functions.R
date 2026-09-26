DetectNormality <- function(df, var, jb_thresh, norm_name){
  # This function detects whether a variable in a dataset is normal based on
  # Jarque-Bera test. A new variable is created saying whether the time series
  # is normal.
  EF_ts <- ts(df[var],
              start = 1995,
              frequency = 1)
  
  jb_results <- jarque.bera.test(EF_ts)
  
  if (is.na(jb_results$p.value)){
    df[norm_name] <- NA
  } else if (jb_results$p.value > a_jb){
    df[norm_name] <- "Yes"
  } else {
    df[norm_name] <- "No"
  }
  return(df)
}

ZScoreOutliers <- function(df, var, thr = 3){
  # This function detects outliers based on a rule that when a abs(z-score) > thr
  # the observation is flagged as an outlier.
  # thr = 3 -> extreme outlier, thr = 2.5 -> potential outlier
  
  df$Z_score_EF <- as.numeric(scale(df[var]))
  df$outlier_low <- fifelse(df$Z_score_EF < -1 * thr, "Yes", "No")
  df$outlier_high <- fifelse(df$Z_score_EF > thr, "Yes", "No")
  df$Z_score_EF <- NULL
  
  if (var == "EXIOBASE EF"){
    names(df)[names(df) == "outlier_low"] <- "EF_outlier_low"
    names(df)[names(df) == "outlier_high"] <- "EF_outlier_high"
  } else if (var == "EXIOBASE_OUT"){
    names(df)[names(df) == "outlier_low"] <- "OUT_outlier_low"
    names(df)[names(df) == "outlier_high"] <- "OUT_outlier_high"
  } else {
    names(df)[names(df) == "outlier_low"] <- "Outlier_low"
    names(df)[names(df) == "outlier_high"] <- "Outlier_high"
  }
  
  return(df)
}

IQROutliers <- function(df, var, thr = 6){
  # This function detects outliers based on an interquartile range rule.
  # An observation is classified as an outlier if:
  # x_t < Q1 - thr * IQR or x_t > Q3 + thr * IQR
  
  Q1 <- as.numeric(quantile(df[[var]], 0.25))
  Q3 <- as.numeric(quantile(df[[var]], 0.75))
  IQR <- Q3 - Q1
  
  df$outlier_low <- fifelse(df[var] < Q1 - (thr * IQR), "Yes", "No")
  df$outlier_high <- fifelse(df[var] > Q3 + (thr * IQR), "Yes", "No")
  
  if (var == "EXIOBASE EF"){
    names(df)[names(df) == "outlier_low"] <- "EF_outlier_low"
    names(df)[names(df) == "outlier_high"] <- "EF_outlier_high"
  } else if (var == "EXIOBASE_OUT"){
    names(df)[names(df) == "outlier_low"] <- "OUT_outlier_low"
    names(df)[names(df) == "outlier_high"] <- "OUT_outlier_high"
  } else {
    names(df)[names(df) == "outlier_low"] <- "Outlier_low"
    names(df)[names(df) == "outlier_high"] <- "Outlier_high"
  }
  
  return(df)
}

OutlierImputate <- function(m = "ent_DF", df, var, out_high, out_low, perc = 0.05){
  # This function imputates outliers in emission factors.
  # m = mode (ent_df = imputate outliers in the entire data frame,
  # ef_and_out = imputate emission factor outliers that are also output outliers,
  # isolated_only = imputate only isolated outliers,
  # negative_isolated = imputate only negative isolated outliers)
  # df = data frame in which the outliers should be imputated,
  # var = variable that should be imputated (mostly the EXIOBASE emission factor),
  # out_high = parameter set to the upper imputation boundary,
  # out_low = parameter set to the lower imputation boundary,
  # perc = percent value to determine cut-off quantile.
  
  for (i in 1:nrow(df)) {
    df$IS_outlier[i] <- ifelse(df[[out_high]][i] == "Yes" | df[[out_low]][i] == "Yes",
                               "Yes",
                               "No")
  }
  
  no_out <- df[df$IS_outlier == "No",]
  p_high <- 1 - perc
  p_low <- perc
  
  q_high <- as.numeric(quantile(no_out[[var]], p_high))
  q_low <- as.numeric(quantile(no_out[[var]], p_low))
  
  out_num_gen <- which(df$IS_outlier == "Yes")
  
  # Imputate high outliers
  if (m == "ent_DF"){
    # Imputate all outliers
    out_num_high <- which(df[out_high] == "Yes")
    out_num_low <- which(df[out_low] == "Yes")
  } else if (m == "ef_and_out"){
    # EF outliers that are also OUT outliers
    out_num_high <- which(df[out_high]== "Yes" & df$OUT_outlier_low == "Yes")
    out_num_low  <- which(df[out_low]== "Yes" & df$OUT_outlier_high == "Yes")
  } else if (m == "isolated_only") {
    # Only isolated EF outliers (no neighbouring outliers)
    out_num_gen_iso <- IsolatedOutliers(out_num_gen)
    out_num_high <- intersect(out_num_gen_iso, which(df[out_high] == "Yes"))
    out_num_low <- intersect(out_num_gen_iso, which(df[out_low] == "Yes"))
  } else if (m == "negative_isolated") {
    # Isolated negative EF values
    neg <- which(df[out_var_name] == "Yes")
    out_num <- IsolatedOutliers(neg) 
  } else {
    # Unknown mode → return data unchanged
    return(df)
  }
  
  for (i in 1:length(out_num_high)) {
    df[[var]][out_num_high[i]] <- q_high
  }
  
  for (i in 1:length(out_num_low)) {
    df[[var]][out_num_low[i]] <- q_low
  }
  
  return(df)
} 

IsolatedOutliers <- function(x) {
  # Returns only isolated indices (i.e. no immediate neighbours ±1)
  x <- sort(unique(x))
  x[(c(Inf, diff(x)) > 1) & (c(diff(x), Inf) > 1)]
}

IsolatedOutliers2 <- function(x) {
  # Returns only isolated indices (i.e. no immediate neighbours ±2)
  x <- sort(unique(x))
  x[(c(Inf, diff(x)) > 2) & (c(diff(x), Inf) > 2)]
}

Last6DropLeading0 <- function(x) {
  x <- as.character(x)
  # trim the last 6 characters (safe even for shorter inputs)
  last6 <- substring(x, pmax(nchar(x) - 6 + 1, 1), nchar(x))
  # if the first of these 6 is ‘0’, remove it
  out <- ifelse(substr(last6, 1, 1) == "0", substr(last6, 2, nchar(last6)), last6)
  # NA stays NA
  out[is.na(x)] <- NA_character_
  out
}

