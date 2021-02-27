#' ---
#' title: "Acquiring EO datasets for eLTER+ sites"
#' author:
#'   - name: Micha Silver
#'   - name: Arnon Karnieli
#' date: "20/02/2021"
#' output:
#'   github_document:
#'     toc: true
#'     toc_depth: 2
#'   pdf_document:
#'     toc: TRUE
#'     toc_depth: 2
#' bibliography: bibliography.bib  
#' ---

## ----libraries, message=FALSE, results='hide', warning=FALSE---------
pkg_list = c("MODIStsp", "lubridate", "raster", "ggplot2",
             "cowplot", "tidyr", "sf", "stars", "leaflet",
             "shiny","shinydashboard","shinyFiles",
             "shinyalert",  "rappdirs","shinyjs", "leafem",
             "mapedit", "magrittr")
installed_packages <- pkg_list %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(pkg_list[!installed_packages])
}
# Packages loading
pkgs = lapply(pkg_list, library, character.only = TRUE)

#' 
#' ### Define directories
## ----directories-----------------------------------------------------
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
site_list_file = "site_shapefiles_url.txt"
site_list = read.csv(site_list_file)
sites = site_list$site_name

# (Add option to ignore Datum unknown warnings)
options("rgdal_show_exportToProj4_warnings"="none")

# Load some helper functions
source("functions.R")

#' 
#' ### Load polygons from DEIMS site
## ----site-polygons, results='hide', message=FALSE, include=FALSE-----
# Call ObtainSitePolygons function (in functions.R)
ObtainSitePolygons(site_list_file)


#' 
#' ### Loop over all sites
#' The download utility used here is "aria2". It can be obtained from:
#' https://github.com/aria2/aria2/releases/tag/release-1.35.0
#' 
#' You **must supply a username and password** for authentication on the EarthData website
#' 
#' This code block will run for a **long** time.
#' 
## ----loop-sites, eval=FALSE------------------------------------------
## #---------------------------------
## # Enter username and password here for EarthData website
user = 'your user name'
password = 'your password'
## #---------------------------------
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

#' ### Site timeseries data
## ----timeseries-averages, warning=FALSE------------------------------
for (site in sites){
  t0 = Sys.time()
  print(paste(t0, "-- Time series for site:", site))
  timeseries_list = TimeSeriesFromRasters(site)
  PlotTimeSeries(timeseries_list, site)
}

## ----CLC-landcover---------------------------------------------------
# Crop Corine Landcover from four years for each site
# Call CropSaveCorine() function for each site

for (site in sites) {
   CropSaveCorine(site)
}
