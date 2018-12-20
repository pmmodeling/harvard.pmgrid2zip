rm(list=ls())
gc()
### load libraries

library(readr)
library(data.table)

#################################################################


#######----- parallel setup (run for each year)
#Retrieve arguments passed from the command line
process <- as.numeric(Sys.getenv("SLURM_ARRAY_TASK_ID"))
#process <- as.integer(as.character(commandArgs(trailingOnly = TRUE)))
#print(process)
jobs <- fread("/n/regal/schwartz_lab/pmgrid/file_yearnr.csv")[, V1 := NULL]
job <- jobs[process]
year <-  job$year
filename <- job$name
cat("year:", year, "\n")
cat("file to process:", filename, "\n")

#######----- Data paths
#use data absolute file paths
#whole us daily pm25 gridded .rds file 
gridded_pm <- paste0("/n/regal/schwartz_lab/pmgrid/",year,"/", filename, ".rds")
#pm25 grid locations
pm_loc <- "/n/regal/schwartz_lab/pmgrid/USPredSite.rds"
#pm2.5 grid location and zipcode linkage (707.11m buffer applied)
pm_loc_zip <- paste0("/n/regal/schwartz_lab/pmgrid/zipcode/pm25_zip_link_", year,".csv")
#pm2.5 grid location and pobox linkage (707.11m buffer applied)
pm_loc_pobox <- paste0("/n/regal/schwartz_lab/pmgrid/pobox/pm25_pobox_link_",year,".csv")

#######----- Load PM2.5 gridded data & grid location and zipcode/pobox linkages in R
#Load pm25 gridded data
pm25 <- readRDS(gridded_pm)
pm_loc <- readRDS(pm_loc)
pm25 <- t(pm25)
pm25 <- pm25[1:11196911, ]
pm25 <- cbind(pm25, pm_loc) 
names(pm25) <- c("pm25", "lon", "lat", "SiteCode")#check for QD's model
setkey(data.table(pm25), SiteCode)
#Load grid location & zipcode/pobox linkage files
loc_zip_link <- setkey(fread(pm_loc_zip), SiteCode)
loc_pobox_link <- setkey(fread(pm_loc_pobox), SiteCode)

loc_zip_link$SiteCode = as.character(loc_zip_link$SiteCode)
loc_pobox_link$SiteCode = as.character(loc_pobox_link$SiteCode)


#######------ Link zipcode/pobox with pm25
pm_zip_link <- merge(loc_zip_link,pm25, by='SiteCode')
pm_pobox_link <- merge(loc_pobox_link,pm25, by='SiteCode')

#######------ Aggregate pm25 at zipcode/pobox level
zip_pm <- setDT(pm_zip_link)[, list(averagepm25 = mean(pm25, na.rm = TRUE)), by = 'zip']
pobox_pm <-setDT(pm_pobox_link)[, list(averagepm25 = mean(pm25, na.rm = TRUE)), by	= 'zip'] 

######----- FINAL: zip areas and PO boxies
pm_link_final <- rbind(zip_pm, pobox_pm)

######----- update different output data paths for qd, rm, ik 
fwrite(pm_link_final, paste0("/n/regal/schwartz_lab/pmgrid/area_weighted/",year, "/", filename,".csv"))
print("write restults to disk")

