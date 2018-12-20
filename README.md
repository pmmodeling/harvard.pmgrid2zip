# harvard.pmgrid2zip

This is the code written by Christine Choirat, Fei Carnes and Yara Abu Awad to calculate the mean PM2.5 at the zip code level 
from grid point predictions of Qian Di's ensemble PM2.5 prediction model for the entire US from 2000 - 2016.

Step 01 is a crosswalk from grid to zip code: 'pm25_zip_pobox_crosswalk_qdnew.R' with input file: 'year_long.csv'.
Step 02: is the merge of grid predictions to zip code and calculation of daily mean at each zip code: 'area_weighted_mean_calculation.R' with input file: 'file_yearnr.csv' and Odyssey cluster submit file: 'area_weighted_submit_file.sh'
