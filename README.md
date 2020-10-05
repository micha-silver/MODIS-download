Download MODIS
================
#### Arnon Karnieli, Micha Silver
#### Remote Sensing Lab, Ben Gurion Univ.
October, 2020

## Setup

Load necessary R libraries, user configurable directories, then read in
the `functions.R` script with contains helper functions for summarizing
layers by date and site, and plotting graphs.

``` r
library(MODIStsp)
library(stars)
```

    ## Loading required package: abind

    ## Loading required package: sf

    ## Linking to GEOS 3.7.1, GDAL 2.4.0, PROJ 5.2.0

``` r
library(sf)
# Edit below as necessary: GIS directory, list of AOI files, and options files
GIS_dir = "/home/micha/work/eLTER/GIS"
Output_dir = "/home/micha/work/eLTER/Output"
site_files = list.files(GIS_dir, pattern = "*gpkg$", full.names = TRUE)
config_files = c("modistsp_options_VI.json", "modistsp_options_LST.json")
# Load some helper functions
source("functions.R")
```

    ## 
    ## Attaching package: 'lubridate'

    ## The following objects are masked from 'package:base':
    ## 
    ##     date, intersect, setdiff, union

    ## Loading required package: sp

    ## 
    ## Attaching package: 'tidyr'

    ## The following object is masked from 'package:raster':
    ## 
    ##     extract

## MODIS products, layers

Display lists of all available products and layers in each product
category.

``` r
MODIStsp_get_prodnames()
```

    ##   [1] "Surf_Ref_8Days_500m (M*D09A1)"                   
    ##   [2] "Surf_Ref_Daily_005dg (M*D09CMG)"                 
    ##   [3] "Surf_Ref_Daily_500m (M*D09GA)"                   
    ##   [4] "Surf_Ref_Daily_250m (M*D09GQ)"                   
    ##   [5] "Surf_Ref_8Days_250m (M*D09Q1)"                   
    ##   [6] "Ocean_Ref_Daily_1Km (M*DOCGA)"                   
    ##   [7] "Therm_Daily_1Km (M*DTBGA)"                       
    ##   [8] "Snow_Cov_Daily_500m (M*D10A1)"                   
    ##   [9] "Snow_Cov_8-Day_500m (M*D10_A2)"                  
    ##  [10] "Snow_Cov_Day_0.05Deg (M*D10C1)"                  
    ##  [11] "Snow_Cov_8-Day0.05Deg CMG (M*D10C2)"             
    ##  [12] "Snow_Cov_Month_0.05Deg CMG (M*D10CM)"            
    ##  [13] "Surf_Temp_Daily_005dg (M*D11C1)"                 
    ##  [14] "Surf_Temp_Daily_1Km (M*D11A1)"                   
    ##  [15] "Surf_Temp_8Days_1Km (M*D11A2)"                   
    ##  [16] "Surf_Temp_Daily_GridSin (M*D11B1)"               
    ##  [17] "Surf_Temp_8Days_GridSin (M*D11B2)"               
    ##  [18] "Surf_Temp_Monthly_GridSin (M*D11B3)"             
    ##  [19] "Surf_Temp_8Days_005dg (M*D11C2)"                 
    ##  [20] "Surf_Temp_Monthly_005dg (M*D11C3)"               
    ##  [21] "LST_3band_emissivity_Daily_1km (M*D21A1D)"       
    ##  [22] "LST_3band_emissivity_Daily_1km_night (M*D21A1N)" 
    ##  [23] "LST_3band_emissivity_8day_1km (M*D21A2)"         
    ##  [24] "BRDF_Albedo_ModelPar_Daily_500m (MCD43A1)"       
    ##  [25] "BRDF_Albedo_Quality_Daily_500m (MCD43A2)"        
    ##  [26] "Albedo_Daily_500m (MCD43A3)"                     
    ##  [27] "BRDF_Adj_Refl_Daily_500m (MCD43A4)"              
    ##  [28] "BRDF_Albedo_ModelPar_Daily_005dg (MCD43C1)"      
    ##  [29] "BRDF_Albedo_Quality_Daily_005dg (MCD43C2)"       
    ##  [30] "Albedo_Daily_005dg (MCD43C3)"                    
    ##  [31] "BRDF_Adj_Refl_16Day_005dg (MCD43C4)"             
    ##  [32] "AlbPar_1_B1_Daily_30ArcSec (MCD43D01)"           
    ##  [33] "AlbPar_2_B1_Daily_30ArcSec (MCD43D02)"           
    ##  [34] "AlbPar_3_B1_Daily_30ArcSec (MCD43D03)"           
    ##  [35] "AlbPar_1_B2_Daily_30ArcSec (MCD43D04)"           
    ##  [36] "AlbPar_2_B2_Daily_30ArcSec (MCD43D05)"           
    ##  [37] "AlbPar_3_B2_Daily_30ArcSec (MCD43D06)"           
    ##  [38] "AlbPar_1_B3_Daily_30ArcSec (MCD43D07)"           
    ##  [39] "AlbPar_2_B3_Daily_30ArcSec (MCD43D08)"           
    ##  [40] "AlbPar_3_B3_Daily_30ArcSec (MCD43D09)"           
    ##  [41] "AlbPar_1_B4_Daily_30ArcSec (MCD43D10)"           
    ##  [42] "AlbPar_2_B4_Daily_30ArcSec (MCD43D11)"           
    ##  [43] "AlbPar_3_B4_Daily_30ArcSec (MCD43D12)"           
    ##  [44] "AlbPar_1_B4_Daily_30ArcSec (MCD43D13)"           
    ##  [45] "AlbPar_2_B4_Daily_30ArcSec (MCD43D14)"           
    ##  [46] "AlbPar_3_B4_Daily_30ArcSec (MCD43D15)"           
    ##  [47] "AlbPar_1_B5_Daily_30ArcSec (MCD43D16)"           
    ##  [48] "AlbPar_2_B5_Daily_30ArcSec (MCD43D17)"           
    ##  [49] "AlbPar_3_B5_Daily_30ArcSec (MCD43D18)"           
    ##  [50] "AlbPar_1_B6_Daily_30ArcSec (MCD43D19)"           
    ##  [51] "AlbPar_2_B6_Daily_30ArcSec (MCD43D20)"           
    ##  [52] "AlbPar_3_B6_Daily_30ArcSec (MCD43D21)"           
    ##  [53] "AlbPar_1_Vis_Daily_30ArcSec (MCD43D22)"          
    ##  [54] "AlbPar_2_Vis_Daily_30ArcSec (MCD43D23)"          
    ##  [55] "AlbPar_3_Vis_Daily_30ArcSec (MCD43D24)"          
    ##  [56] "AlbPar_1_NIR_Daily_30ArcSec (MCD43D25)"          
    ##  [57] "AlbPar_2_NIR_Daily_30ArcSec (MCD43D26)"          
    ##  [58] "AlbPar_3_NIR_Daily_30ArcSec (MCD43D27)"          
    ##  [59] "AlbPar_1_SWIR_Daily_30ArcSec (MCD43D28)"         
    ##  [60] "AlbPar_2_SWIR_Daily_30ArcSec (MCD43D29)"         
    ##  [61] "AlbPar_3_SWIR_Daily_30ArcSec (MCD43D30)"         
    ##  [62] "BRDF_Albedo_Quality_Daily_30ArcSec (MCD43D31)"   
    ##  [63] "BRDF_Albedo_SolNoon_Daily_30ArcSec (MCD43D32)"   
    ##  [64] "Alb_ValObs_B1_Daily_30ArcSec (MCD43D33)"         
    ##  [65] "Alb_ValObs_B2_Daily_30ArcSec (MCD43D34)"         
    ##  [66] "Alb_ValObs_B3_Daily_30ArcSec (MCD43D35)"         
    ##  [67] "Alb_ValObs_B4_Daily_30ArcSec (MCD43D36)"         
    ##  [68] "Alb_ValObs_B5_Daily_30ArcSec (MCD43D37)"         
    ##  [69] "Alb_ValObs_B6_Daily_30ArcSec (MCD43D38)"         
    ##  [70] "Alb_ValObs_B7_Daily_30ArcSec (MCD43D39)"         
    ##  [71] "BRDF_Albedo_Snow_Daily_30ArcSec (MCD43D40)"      
    ##  [72] "BRDF_Alb_Unc_Daily_30ArcSec (MCD43D41)"          
    ##  [73] "BRDF_Alb_BSA_B1_Daily_30ArcSec (MCD43D42)"       
    ##  [74] "BRDF_Alb_BSA_B2_Daily_30ArcSec (MCD43D43)"       
    ##  [75] "BRDF_Alb_BSA_B3_Daily_30ArcSec (MCD43D44)"       
    ##  [76] "BRDF_Alb_BSA_B4_Daily_30ArcSec (MCD43D45)"       
    ##  [77] "BRDF_Alb_BSA_B5_Daily_30ArcSec (MCD43D46)"       
    ##  [78] "BRDF_Alb_BSA_B6_Daily_30ArcSec (MCD43D47)"       
    ##  [79] "BRDF_Alb_BSA_B7_Daily_30ArcSec (MCD43D48)"       
    ##  [80] "BRDF_Alb_BSA_Vis_Daily_30ArcSec (MCD43D49)"      
    ##  [81] "BRDF_Alb_BSA_NIR_Daily_30ArcSec (MCD43D50)"      
    ##  [82] "BRDF_Alb_BSA_SWIR_Daily_30ArcSec (MCD43D51)"     
    ##  [83] "BRDF_Alb_WSA_B1_Daily_30ArcSec (MCD43D52)"       
    ##  [84] "BRDF_Alb_WSA_B2_Daily_30ArcSec (MCD43D53)"       
    ##  [85] "BRDF_Alb_WSA_B3_Daily_30ArcSec (MCD43D54)"       
    ##  [86] "BRDF_Alb_WSA_B4_Daily_30ArcSec (MCD43D55)"       
    ##  [87] "BRDF_Alb_WSA_B5_Daily_30ArcSec (MCD43D56)"       
    ##  [88] "BRDF_Alb_WSA_B6_Daily_30ArcSec (MCD43D57)"       
    ##  [89] "BRDF_Alb_WSA_B7_Daily_30ArcSec (MCD43D58)"       
    ##  [90] "BRDF_Alb_WSA_Vis_Daily_30ArcSec (MCD43D59)"      
    ##  [91] "BRDF_Alb_WSA_NIR_Daily_30ArcSec (MCD43D60)"      
    ##  [92] "BRDF_Alb_WSA_SWIR_Daily_30ArcSec (MCD43D61)"     
    ##  [93] "BRDF_Albedo_NBAR_Band1_Daily_30ArcSec (MCD43D62)"
    ##  [94] "BRDF_Albedo_NBAR_Band2_Daily_30ArcSec (MCD43D63)"
    ##  [95] "BRDF_Albedo_NBAR_Band3_Daily_30ArcSec (MCD43D64)"
    ##  [96] "BRDF_Albedo_NBAR_Band4_Daily_30ArcSec (MCD43D65)"
    ##  [97] "BRDF_Albedo_NBAR_Band5_Daily_30ArcSec (MCD43D66)"
    ##  [98] "BRDF_Albedo_NBAR_Band6_Daily_30ArcSec (MCD43D67)"
    ##  [99] "BRDF_Albedo_NBAR_Band7_Daily_30ArcSec (MCD43D68)"
    ## [100] "Vegetation_Indexes_16Days_500m (M*D13A1)"        
    ## [101] "Vegetation_Indexes_16Days_1Km (M*D13A2)"         
    ## [102] "Vegetation_Indexes_Monthly_1Km (M*D13A3)"        
    ## [103] "Vegetation_Indexes_16Days_005dg (M*D13C1)"       
    ## [104] "Vegetation_Indexes_Monthly_005dg (M*D13C2)"      
    ## [105] "Vegetation Indexes_16Days_250m (M*D13Q1)"        
    ## [106] "LAI_8Days_500m (MCD15A2H)"                       
    ## [107] "LAI_4Days_500m (MCD15A3H)"                       
    ## [108] "LAI_8Days_500m (M*D15A2H)"                       
    ## [109] "Net_ET_8Day_500m (M*D16A2)"                      
    ## [110] "Net_ET_Yearly_500m (M*D16A3)"                    
    ## [111] "Gross_PP_8Days_500m (M*D17A2H)"                  
    ## [112] "Net_PP_Yearly_500m (M*D17A3H)"                   
    ## [113] "Veg_Cont_Fields_Yearly_250m (MOD44B)"            
    ## [114] "Land_Wat_Mask_Yearly_250m (MOD44W)"              
    ## [115] "Burned_Monthly_500m (MCD64A1)"                   
    ## [116] "ThermalAn_Fire_Daily_1Km (M*D14A1)"              
    ## [117] "ThermalAn_Fire_8Days_1Km (M*D14A2)"              
    ## [118] "LandCover_Type_Yearly_005dg (MCD12C1)"           
    ## [119] "LandCover_Type_Yearly_500m (MCD12Q1)"            
    ## [120] "LandCover_Dynamics_Yearly_500m (MCD12Q2)"        
    ## [121] "Dwnwrd_Srw_Rad_3h_005dg (MCD18A1)"               
    ## [122] "Dwnwrd_PAR_3h_005dg (MCD18A2)"                   
    ## [123] "MAIA_Land_Surf_BRF (MCD19A1)"                    
    ## [124] "MAIA_Land_AOT_daily (MCD19A2)"

``` r
# [105] "Vegetation Indexes_16Days_250m (M*D13Q1)"
# [23] "LST_3band_emissivity_8day_1km (M*D21A2)"
```

``` r
MODIStsp_get_prodlayers("Vegetation Indexes_16Days_250m (M*D13Q1)")
```

    ## $prodname
    ## [1] "Vegetation Indexes_16Days_250m (M*D13Q1)"
    ## 
    ## $bandnames
    ##  [1] "NDVI"     "EVI"      "VI_QA"    "b1_Red"   "b2_NIR"   "b3_Blue" 
    ##  [7] "b7_SWIR"  "View_Zen" "Sun_Zen"  "Rel_Az"   "DOY"      "Rely"    
    ## 
    ## $bandfullnames
    ##  [1] "16 day NDVI average"                "16 day EVI average"                
    ##  [3] "VI quality indicators"              "Surface Reflectance Band 1"        
    ##  [5] "Surface Reflectance Band 2"         "Surface Reflectance Band 3"        
    ##  [7] "Surface Reflectance Band 7"         "View zenith angle of VI pixel"     
    ##  [9] "Sun zenith angle of VI pixel"       "Relative azimuth angle of VI pixel"
    ## [11] "Day of year of VI pixel"            "Quality reliability of VI pixel"   
    ## 
    ## $quality_bandnames
    ## [1] "QA_qual"     "QA_usef"     "QA_aer"      "QA_adj_cld"  "QA_BRDF"    
    ## [6] "QA_mix_cld"  "QA_land_wat" "QA_snow_ice" "QA_shd"     
    ## 
    ## $quality_fullnames
    ## [1] "VI Quality"                          
    ## [2] "VI usefulness"                       
    ## [3] "Aerosol quantity"                    
    ## [4] "Adjacent cloud detected"             
    ## [5] "Atmosphere BRDF correction performed"
    ## [6] "Mixed Clouds"                        
    ## [7] "Land/Water Flag"                     
    ## [8] "Possible snow/ice"                   
    ## [9] "Possible shadow"                     
    ## 
    ## $indexes_bandnames
    ## [1] "SR"    "NDFI"  "NDII7" "SAVI" 
    ## 
    ## $indexes_fullnames
    ## [1] "Simple Ratio (NIR/Red)"              
    ## [2] "Flood Index (Red-SWIR2)/(Red+SWIR2)" 
    ## [3] "NDII7 (NIR-SWIR2)/(NIR+SWIR2)"       
    ## [4] "SAVI (NIR-Red)/(NIR+Red+0.5)*(1+0.5)"

``` r
MODIStsp_get_prodlayers("LST_3band_emissivity_8day_1km (M*D21A2)")
```

    ## $prodname
    ## [1] "LST_3band_emissivity_8day_1km (M*D21A2)"
    ## 
    ## $bandnames
    ##  [1] "LST_Day_1KM"      "QC_Day"           "View_Angle_Day"   "View_Time_Day"   
    ##  [5] "LST_Night_1KM"    "QC_Night"         "View_Angle_Night" "View_Time_Night" 
    ##  [9] "Emis_29"          "Emis_31"          "Emis_32"         
    ## 
    ## $bandfullnames
    ##  [1] "Day Land surface temperature"        
    ##  [2] "Day Quality Control (QC)"            
    ##  [3] "Day MODIS view zenith angle"         
    ##  [4] "Time of MODIS observation for day"   
    ##  [5] "Night Land Surface Temperature"      
    ##  [6] "Night Quality Control (QC)"          
    ##  [7] "Night view zenith angle"             
    ##  [8] "Time of Observation for night"       
    ##  [9] "Average Day/Night Band 29 emissivity"
    ## [10] "Average Day/Night Band 31 emissivity"
    ## [11] "Average Day/Night Band 32 emissivity"
    ## 
    ## $quality_bandnames
    ## [1] "QA_mandatory_Day"   "data_qual_Day"      "emiss_acc_day"     
    ## [4] "lst_acc_day"        "QA_mandatory_Night" "data_qual_Night"   
    ## [7] "emiss_acc_night"    "lst_acc_night"     
    ## 
    ## $quality_fullnames
    ## [1] "Mandatory QA flags Day"    "Data quality flag Day"    
    ## [3] "Emissivity Accuracy Day"   "LST Accuracy Day"         
    ## [5] "Mandatory QA flags Night"  "Data quality flag Night"  
    ## [7] "Emissivity Accuracy Night" "LST Accuracy Night"       
    ## 
    ## $indexes_bandnames
    ## NULL
    ## 
    ## $indexes_fullnames
    ## NULL

## Use the GUI

Here the user can choose:

  - product, layers
  - start and end dates
  - a polygon area of interest (shapefile or Geopackage)
  - and satellite platforms

<!-- end list -->

``` r
MODIStsp()
```

    ## GDAL version in use: 2.4.0

    ## Loading required package: shiny

    ## 
    ## Listening on http://127.0.0.1:7567

## Loop over all sites

Call the MODIStsp() function with `gui = FALSE` and point to a json
formated options file to run the download. The options file was saved
from the GUI step above. This loop downloads all available MODIS tiles
for each AOI.

(Commented out below, as this will take a *long* time)

``` r
# for (opts in config_files) {
#   lapply(1:length(site_files), FUN = function(s) {
#     site_file = site_files[s]
#     
#     MODIStsp(gui = FALSE,
#            opts_file = opts,
#            spafile = site_file,
#            #start_date = "2018.10.01", # To change the dates
#            #sensor = "Aqua",  # "Terra" or "Both"
#            downloader = "aria2", # "html" or "aria2" if it is installed
#            )
#   })
# }
```

## Summary of pixels in each site

Loop over all sites and summarize pixels by date for each site. The
functions used here are stored in `functions.R`

#### Vegetation indices

``` r
# site_names = lapply(site_files, FUN = function(f) {
#                       tools::file_path_sans_ext(basename(f))})
# 
# lapply(1:length(site_names), FUN = function(s) {
#   # Get site polygon as sf object
#   site_name = site_names[[s]]
#   site = read_sf(site_files[s])
#   
#   # Extract NDVI and EVI time series, and plot
#   VI_folder = file.path(Output_dir, site_name,
#                         "VI_16Days_250m_v6")
#   # NDVI
#   mod_stars = StarsFromFolder(VI_folder, site, "NDVI")
#   NDVI_df = ValuesFromStars(mod_stars, "NDVI")
#   date_df = DatesFromFolder(file.path(VI_folder, "NDVI"))
#   #cnt_df = PixelCountFromStars(mod_stars)
#   cnt_df = PixelCountFromFolder(
#     file.path(VI_folder, "NDVI"), site)
#   # EVI
#   mod_stars = StarsFromFolder(VI_folder, site, "EVI")
#   EVI_df = ValuesFromStars(mod_stars, "EVI")
#   VI_df = cbind(date_df, NDVI_df, EVI_df, cnt_df)
#   PlotSave(site_name, VI_df, "VI")
# })
```

#### Land surface temperature

```` r
# site_names = lapply(site_files, FUN = function(f) {
#                       tools::file_path_sans_ext(basename(f))})
# 
# lapply(1:length(site_names), FUN = function(s) {
#   # Extract LST day and night time series, and plot
#   LST_folder = file.path(Output_dir, site_name,
#                          "LST_3band_emissivity_8day_1km")
#   # Day
#   mod_stars = StarsFromFolder(LST_folder, site, "LST_Day_1KM")
#   LST_day = ValuesFromStars(mod_stars, "LST_Day_1KM")
#   date_df = DatesFromFolder(file.path(LST_folder, "LST_Day_1KM"))
#   # cnt_df = PixelCountFromStars(mod_stars)
#   cnt_df = PixelCountFromFolder(
#     file.path(LST_folder, "LST_Day_1KM"), site)
#   # Night
#   mod_stars = StarsFromFolder(LST_folder, site, "LST_Night_1KM")
#   LST_night = ValuesFromStars(mod_stars, "LST_Night_1KM")
# 
#   LST_df = cbind(date_df, LST_day, LST_night, cnt_df)
#   PlotSave(site_name, LST_df, "LST")
# })
# ```
# 
````

#### Corine Landcover for four years of CLC rasters

```` r
# ## Crop Corine Landcover from four years for each site
# ```{r corine_landcover}
# corine_basedir = "/home/micha/GIS/Corine_CLC"
# corine_datadirs = list.dirs(path = corine_basedir)
# corine_datadirs = corine_datadirs[grepl(pattern = "DATA$", x = corine_datadirs)]
# corine_list = sapply(corine_datadirs, 
#                      FUN = function(d) {list.files(d,
#                                                    pattern = ".*tif$",
#                                                    full.names = TRUE)},
#                      USE.NAMES = FALSE)
# site_names = lapply(site_files, FUN = function(f) {
#                       tools::file_path_sans_ext(basename(f))})
# 
# for (s in 1:length(site_names)) {
#   site_name = site_names[[s]]
#   site = read_sf(site_files[s])
#   # Transform site boundary to LAEA ETRS89 to match Corine data
#   site = st_transform(site, crs=3035)
#   for (clc_path in corine_list) {
#       clc = read_stars(clc_path)
#       CropSaveCorine(clc, clc_path, site, site_name)
#   }
# }
````
