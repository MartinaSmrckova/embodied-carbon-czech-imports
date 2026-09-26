## =========================================================
## 0) Load libraries
## =========================================================
library(readxl)
library(dplyr)
library(purrr)
library(data.table)
library(writexl)

## =========================================================
## 1) Load trade data
## =========================================================
path <- "C:\\Users\\Martina\\Documents\\Škola\\Články\\Carbon footprint 2025\\Data\\Scope 3U calculation\\WITS Imports"
files <- list.files(path, pattern = "\\.csv$", full.names = TRUE)

imp_list <- list()

for (i in 1:length(files)) {
  imp_list[[i]] <- read.csv(files[i])
}

# Clear the partner names
imp_all <- data.table(do.call(rbind, imp_list))

# unique_partners <- unique(imp_all[, c("PartnerName", "PartnerISO3")])
# write_xlsx(unique_partners,
          # "C:\\Users\\Martina\\Documents\\Škola\\Články\\Carbon footprint 2025\\Data\\Scope 3U calculation\\WITS_partners.xlsx")

## =========================================================
## 2) Delete data on unspecified partner countries and the
##    Czech Republic
## =========================================================
partners_to_del <- c("World",
                     " World",
                     "Czech Republic",
                     "Bunkers",
                     "Free Zones",
                     "Special Categories",
                     "Unspecified")

imp_all <- data.frame(imp_all)
imp_all <- imp_all[!(imp_all$PartnerName %in% partners_to_del),]

## =========================================================
## 3) Convert trade values from USD to EURm
## =========================================================
# Load the data with exchange rates
data <- read_xlsx("C:\\Users\\Martina\\Documents\\Škola\\Články\\Carbon footprint 2025\\Data\\Data_CR.xlsx")

imp_all <- merge(imp_all, data[c("Year", "EUR_USD")], by = "Year", all.x = TRUE)
imp_all$TradeValue.in.1000.USD <- as.numeric(imp_all$TradeValue.in.1000.USD)


imp_all$`Trade Value EURm` <- (imp_all$TradeValue.in.1000.USD * imp_all$EUR_USD)/1000

imp_all$TradeValue.in.1000.USD <- NULL
imp_all$EUR_USD <- NULL
imp_all$TradeFlowCode <- NULL
imp_all$ReporterName <- NULL
imp_all$TradeFlowName <- NULL
imp_all$QuantityToken <- NULL

names(imp_all)[names(imp_all) == 'ProductCode'] <- 'HS6 ID'
names(imp_all)[names(imp_all) == 'ProductDescription'] <- 'HS6'
names(imp_all)[names(imp_all) == 'PartnerName'] <- 'country_origin'

imp_all$`HS6 ID` <- Last6DropLeading0(imp_all$`HS6 ID`)

imp_all$EURm_kg <- imp_all$`Trade Value EURm` / imp_all$Quantity 

# Regroup the imports by year
imp_by_year <- split(data.table(imp_all), by = "Year")
names(imp_by_year) <- paste("year", names(imp_by_year), sep = "_")

## =========================================================
## 4) Add missing values for Russian natural gas in 2005
## =========================================================
# The data on natural gas imports in 2005 were missing from the WITS database
# for unknown reasons. I got the supplementary information on imported volumes
# from the Energy Regulatory Office of the Czech Republic.
gas_RU_m3 <- 7020000000
gas_NO_m3 <- 2338000000

# Density in 15°C and 101 325 Pa
# Density data source: "https://www.tzb-info.cz/tabulky-a-vypocty/90-hustota-zemnich-plynu-v-zavislosti-na-teplote"

gas_dens_RU <- 0.692
gas_dens_NO <- 0.802

gas_RU_kg <- gas_RU_m3 * gas_dens_RU
gas_NO_kg <- gas_NO_m3 * gas_dens_NO
  
# Imputate the data
gas_RU <- data.frame(
  Year = "2005",
  ReporterISO3 = "CZE",
  `HS6 ID` = "271121",
  PartnerISO3 = "RUS",
  Nomenclature = "H0",
  country_origin = "Russian Federation",
  Quantity = gas_RU_kg,
  QtyUnit = "Kg",
  HS6 = "Natural gas in gaseous state",
  `Trade Value EURm` = NA,
  EURm_kg <- NA,
  stringsAsFactors = FALSE
)

colnames(gas_RU) <- colnames(imp_by_year$year_2005)

gas_NO <- data.frame(
  Year = "2005",
  ReporterISO3 = "CZE",
  `HS6 ID` = "271121",
  PartnerISO3 = "NOR",
  Nomenclature = "H0",
  country_origin = "Norway",
  Quantity = gas_NO_kg,
  QtyUnit = "Kg",
  HS6 = "Natural gas in gaseous state",
  `Trade Value EURm` = NA,
  EURm_kg <- NA,
  stringsAsFactors = FALSE
)

colnames(gas_NO) <- colnames(imp_by_year$year_2005)
imp_by_year$year_2005 <- rbind(imp_by_year$year_2005,
                               gas_RU,
                               gas_NO)

imp_by_year$year_2005$Year <- as.numeric(imp_by_year$year_2005$Year)

# Imputate the import values in RU and NO natural gas
imp_by_year_all <- (do.call(rbind, imp_by_year)) 

imp_by_product <- split(
  imp_by_year_all,
  list(
    imp_by_year_all$country_origin,
    imp_by_year_all$`HS6 ID`
  ),
  drop = TRUE
)

imp_by_product[["Russian Federation.271121"]]$EURm_kg[11] <-
  mean(c(imp_by_product[["Russian Federation.271121"]]$EURm_kg[10],
       imp_by_product[["Russian Federation.271121"]]$EURm_kg[12]))

imp_by_product[["Norway.271121"]]$EURm_kg[8] <-
  mean(c(imp_by_product[["Norway.271121"]]$EURm_kg[7],
         imp_by_product[["Norway.271121"]]$EURm_kg[9]))

imp_by_product[["Russian Federation.271121"]]$`Trade Value EURm`[11] <- imp_by_product[["Russian Federation.271121"]]$EURm_kg[11] * imp_by_product[["Russian Federation.271121"]]$Quantity[11]
imp_by_product[["Norway.271121"]]$`Trade Value EURm`[8] <- imp_by_product[["Norway.271121"]]$EURm_kg[8] * imp_by_product[["Norway.271121"]]$Quantity[8]

# Regroup the data by years
imp_by_year_all <- (do.call(rbind, imp_by_product))

imp_by_year <- split(data.table(imp_by_year_all), by = "Year")
names(imp_by_year) <- paste("year", names(imp_by_year), sep = "_")
imp_by_year <- imp_by_year[order(as.integer(sub("year_", "", names(imp_by_year))))]
