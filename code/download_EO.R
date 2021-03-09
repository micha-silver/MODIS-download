## ----------------------
# Setup
## ----------------------

# libraries
pkg_list = c("MODIStsp", "lubridate", "raster", "terra",
             "tidyr", "sf", "stars", "leaflet",
             "shiny","shinydashboard","shinyFiles",
             "shinyalert",  "rappdirs","shinyjs", "leafem",
             "mapedit", "magrittr")
installed_packages <- pkg_list %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(pkg_list[!installed_packages], dependencies = TRUE)
}
# Package loading
pkgs = lapply(pkg_list, library, character.only = TRUE)


## ----directories
# Edit below as necessary: GIS, output, and figures directories
# and read options and sites files
GIS_dir = "../GIS"
if (!dir.exists(GIS_dir)) {dir.create(GIS_dir,
                                      recursive = TRUE)}

# Where to save outputs
Output_dir = "../Output"
if (!dir.exists(Output_dir)) {dir.create(Output_dir,
                                         recursive = TRUE)}

# Where to save figures
Figures_dir = "../Figures"
if (!dir.exists(Figures_dir)) {dir.create(Figures_dir,
                                         recursive = TRUE)}

# List of eLTER+ sites and DEIMS URL's for download
site_list_file = "site_shapefiles_url.csv"
site_list = read.csv(site_list_file)
sites = site_list$site_name

# List of available ODC rasters, with file names
# Download from: 
raster_list_url <- "https://gitlab.com/geoharmonizer_inea/eumap/-/raw/master/gh_raster_layers.csv?inline=false"
ODS_list_file = "gh_raster_layers.csv"
download.file(url = raster_list_url, destfile = ODS_list_file)
ODS_list = read.csv(ODS_list_file, sep = ";")

# Subset list of NDVI only
ODS_NDVI_list = ODS_list[grepl("ndvi",
                               ODS_list$name, fixed = TRUE),]

# (Add option to ignore Datum unknown warnings)
options("rgdal_show_exportToProj4_warnings"="none")

# Load some helper functions
source("functions.R")

## site-polygons
# Call ObtainSitePolygons function (in functions.R)
ObtainSitePolygons(site_list_file)

## ----------------------
# MODIS-products
## ----------------
MODIS_products = MODIStsp_get_prodnames()
# Vegetation products:
print("Vegetation Index products:")
MODIS_products[grepl("Vegetation", MODIS_products)]
cat('\n')
# Land surface temperature products:
print("Land Surface Temperature products")
MODIS_products[grepl("LST", MODIS_products)]
# ... many more

# GUI
# Interactive configuration for MODIS download
# MODIStsp()

## ----------------
# loop-sites
## ----------------
# Enter username and password here for EarthData website
user = 'your user name'
password = 'your password'
config_files = list.files(".", pattern = ".json$",
                         full.names = TRUE)
spatial_files = list.files(GIS_dir, pattern = ".gpkg$",
                          full.names = TRUE)

# Loop over sites
lapply(spatial_files, FUN = function(site) {
  t0 = Sys.time()
   site_name = basename(tools::file_path_sans_ext(site))
   print(paste(t0, "-- Processing site:", site_name))
   # Loop over configurations
   lapply(config_files, FUN = function(cfg) {
     MODIStsp(gui = FALSE,
            opts_file = cfg,
            spafile = site,
            spameth = "file",
            user = user,
            password = password,
            #start_date = "2018.10.01", # To change the dates
            #sensor = "Aqua",  # "Terra" or "Both"
            downloader = "aria2", # "html" or "aria2" if it is installed
            verbose = FALSE
            )
   })
   t1 = Sys.time()
   elapsed = round(difftime(t1, t0, units = "mins"))
   print(paste(t0, "-- Completed site:", site_name,
               "in", elapsed, "mins"))
 })

## ----------------
# timeseries-averages
## ----------------
# Call TimeSeriesFromRaster() function for each site
# Create graphs of each time series with PlotTimeSeries() function
for (site in sites){
  t0 = Sys.time()
  print(paste(t0, "-- Time series for site:", site))
  timeseries_list = TimeSeriesFromRasters(site)
  PlotTimeSeries(timeseries_list, site)
}


## ----CLC-landcover
# Crop Corine Landcover from four years for each site
# Call CropSaveCorine() function for each site
for (site in sites) {
   CropSaveCorine(site)
}


## ----------------
# High resolution EO data from OpenDataScience
## ----------------
# load-tereno
site = "Tereno"
site_gpkg = paste0(site, ".gpkg")
site_sf = read_sf(file.path(GIS_dir, site_gpkg))
# Transform to ETRS89 CRS to match OpenDataScience layers
site_sf_ETRS = st_transform(site_sf, 3035)

# Where to save High resolution outputs
Highres_dir = file.path(Output_dir, site, "NDVI_Highres")
if (!dir.exists(Highres_dir)) {dir.create(Highres_dir,
                                          recursive = TRUE)}

# read-crop-rasters
ODS_wasabi = "https://s3.eu-central-1.wasabisys.com/"

# Loop thru list of NDVI rasters from OpenDataScience site
lapply(1:length(ODS_NDVI_list$name), FUN = function(x){
  ods_folder = ODS_NDVI_list$folder[x]
  ods_name = ODS_NDVI_list$name[x]

  # Extract the year-month from tif name.
  # Use this string to save new Geotiff
  yrmo = unlist(strsplit(ods_name, split = "_", fixed = TRUE))[7]
  yrmo = paste(substr(yrmo, 5, 6), substr(yrmo, 1, 4), sep="-")
  site_tif = paste(site, "NDVI", "Hires", yrmo, sep="_")
  site_path = file.path(Highres_dir, paste0(site_tif, ".tif"))

  ods_url = paste0("/vsicurl/",
                   ODS_wasabi, ods_folder, "/", ods_name)
  rast_ndvi = terra::rast(ods_url)
  site_ndvi = crop(rast_ndvi, vect(site_sf_ETRS))
  #Revert to original NDVI, undo the COG value
  site_ndvi = (site_ndvi - 100) / 100.0
  terra::writeRaster(site_ndvi, site_path, overwrite = TRUE)
})
