library(tidyr)
library(dplyr)

# To RUN ON HPC
setwd("/ABSOLUTE/PATH/TO/WM_csv_wrangling/")
region_names <- read.csv('MASK_Output_Order.csv', header = FALSE)

# Get the name of all subject csv files
sbj_csvs <- list.files('CSVs', pattern = ".csv", full.names = TRUE)

# Create a dataframe to keep all subject's WM results
# Note: the value 5 comes from having 5 modalities here
WM_regionwise <- data.frame(matrix(nrow = 5*length(sbj_csvs), ncol = nrow(region_names)+2))
colnames(WM_regionwise)[1] <- "Subject_ID"
colnames(WM_regionwise)[2] <- "WM_Measure"
colnames(WM_regionwise)[3:ncol(WM_regionwise)] <- region_names[,1]


# Read subjects one by one and add to the WM_regionwise dataframe
for (i in 1:length(sbj_csvs)) {
  print(i)
  flush.console()

  sbj <- tryCatch({read.csv(sbj_csvs[i], header = FALSE)}, error=function(e) { data.frame() })
  if (nrow(sbj) > 0) {
    sbj_id <- substr(sbj_csvs[i],10,16)
    sbj[,1] <- sapply(strsplit(sbj[, 1], "_"), function(x) toupper(x[4]))
  
    WM_regionwise[(((i-1)*5)+1):(((i-1)*5)+nrow(sbj)),1] <- sbj_id
    WM_regionwise[(((i-1)*5)+1):(((i-1)*5)+nrow(sbj)),2] <- sbj[,1]
    WM_regionwise[(((i-1)*5)+1):(((i-1)*5)+nrow(sbj)),3:ncol(WM_regionwise)] <- sbj[,2:ncol(sbj)]
  }
}

# Remove empty lines
WM_regionwise <- WM_regionwise %>% filter(!is.na(Subject_ID))

# Save in ./WM_csv_wrangling/
write.csv(WM_regionwise,'UKB_WM_Regionwise_Data.csv', row.names=FALSE)



