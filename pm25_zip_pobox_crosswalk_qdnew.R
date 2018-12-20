##########################################################################################
######## The script creates the crosswalks between pm2.5 grids and zipcode/pobox  ########
########              to use for pm2.5 predication aggregation                    ########
########  (works specifically for QD's new pm2.5 predictions in RCE environment)  ######## 
##########################################################################################

library(data.table)
library(readr)
library(rgdal)
library(rowr)
library(raster)
library(rgeos)
library(dplyr)

#####################################################
#######   parallel setup (run for each year)   ######
#####################################################

#Retrieve arguments passed from the command line
process <- as.integer(commandArgs(trailingOnly = T)[1]) + 1
print(process)
jobs <- fread("../year_long.csv")[, V1 := NULL]
job <- jobs[process]
year <-  job$year
cat("year:", formatC(year, width=2, flag="0"), "\n")

#####################################################
##############       Load data       ################
#####################################################
#data source
#pm25 grid locations
pm_loc <- "[..]/qd_predictions_ensemble/USPredSite.rds"
#zipcode polygon shapefile (dsn is for directory, layer is the file name withtout extension)
zipcode <- readOGR(dsn="[..]",layer=paste0("ESRI",formatC(year, width=2, flag="0"),"USZIP5_POLY_WGS84"))
#pobox point csv
pobox_csv <- paste0("[..]/ESRI",formatC(year, width=2, flag="0"),"USZIP5_POINT_WGS84_POBOX.csv")

##########----- Load pm25 grid location and reproject
pm25_loc <- readRDS(pm_loc)
names(pm25_loc) <- c("lon", "lat", "SiteCode")
#convert into spdf
coordinates(pm25_loc) <- ~lon+lat
proj4string(pm25_loc) <- proj4string(zipcode)
#reproject pm25_loc file
pcs <- "+proj=laea +lat_0=45 +lon_0=-100 +x_0=0 +y_0=0 +a=6370997 +b=6370997 +units=m +no_defs"
pm25_loc_proj <- spTransform(pm25_loc, crs(pcs))

##########----- Load zipcode/pobox and reproject
pobox <- fread(pobox_csv)
coordinates(pobox) <- ~ POINT_X+POINT_Y
proj4string(pobox) <- proj4string(zipcode)
#reproject and buffer zipcode and pobox
zipcode_proj_buffer <- gBuffer(spTransform(zipcode, crs(pcs)), width=707.11, byid= T)
pobox_proj_buffer <- gBuffer(spTransform(pobox, crs(pcs)), width=707.11, byid= T)

#################################################################################
##############        spatial join zip/pobox with pm25 spdf      ################
#################################################################################

zip_link <- sp::over(zipcode_proj_buffer, pm25_loc_proj, returnList=TRUE)
pobox_link <- sp::over(pobox_proj_buffer, pm25_loc_proj, returnList=TRUE)

#######################################################################
##############        crosswalk for zipcode/pobox      ################
#######################################################################

#########------ zipcode and pm25 crosswalk
for (i in 1:nrow(zipcode@data)){
  if (length(zip_link[[i]]$SiteCode)>0){
    zip_link[[i]]$zip <- as.character(zipcode@data[i,]$ZIP)
  }
}
zip_link_final <- dplyr::bind_rows(zip_link)

#########------ pobox and pm25 crosswalk
for (i in 1:nrow(pobox@data)){
  if (length(pobox_link[[i]]$SiteCode)>0){
    pobox_link[[i]]$zip <- as.character(pobox@data[i,]$ZIP)
  }
}
pobox_link_final <- dplyr::bind_rows(pobox_link)

########-------     write to disk
write.csv(zip_link_final, paste0("[..]/pm25_zip_link_20", formatC(year, width=2, flag="0"), ".csv"))
write.csv(pobox_link_final, paste0("[..]/qd/pm25_pobox_link_20", formatC(year, width=2, flag="0"), ".csv"))
