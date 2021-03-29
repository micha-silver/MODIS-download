## ----setup, include=FALSE----------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)


## ----libraries, message=FALSE, results='hide', warning=FALSE-----------------
pkg_list = c("terra", "sf", "tmap", "tmaptools", "OpenStreetMap", "dplyr")
installed_packages <- pkg_list %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(pkg_list[!installed_packages], dependencies = TRUE)
}
# Packages loading
pkgs = lapply(pkg_list, library, character.only = TRUE)


## ----directories, message=FALSE, results='hide'-------------------------------
# Edit below as necessary: GIS, output directories
GIS_dir = "../GIS"
CLC_dir = file.path(GIS_dir, "CLC")

# Where to save outputs
Output_dir = "../Output/Corine_Landcover"
if (!dir.exists(Output_dir)) {dir.create(Output_dir,
                                         recursive = TRUE)}

# (Add option to ignore Datum unknown warnings)
options("rgdal_show_exportToProj4_warnings"="none")


## ----deims-corine------------------------------------------------------------
deims_gpkg = file.path(GIS_dir, "DEIMS_sites.gpkg")
deims = read_sf(deims_gpkg, layer = "sites_eu")

clc_list = list.files(CLC_dir, pattern = ".tif$",
                      full.names = TRUE)

# Read in list of CLC files using terra package
clc = rast(clc_list)
# Reproject deims to match the Corine data
# ETRS 89 LAEA (European) coordinate system, EPSG 3035
deims = st_transform(deims, st_crs(clc))


## ----select-site-------------------------------------------------------------
country_list = unique(deims$Country)


lapply(country_list, function(cntry) {
  deims_country = deims[deims$Country == cntry,]
  Country_dir = file.path(Output_dir, cntry)
  if (!dir.exists(Country_dir)) {
    dir.create(Country_dir)
  }

  # Now do cookie cutting for each site within chosen country
  clc_cookiecut = lapply(1:nrow(deims_country), function(s) {
    site = deims_country[s,]
    # Prepare file name to save Clipped CLC
    tif_name = paste(site$Site, site$Location, site$Country, sep = "_")
    tif_name = tolower(tif_name)
    tif_name = gsub(pattern = " ", replacement = "_",
                    x = tif_name)
    tif_name = gsub(pattern = "(", replacement = "",
                    x = tif_name, fixed = TRUE)
    tif_name = gsub(pattern = ")", replacement = "",
                    x = tif_name, fixed = TRUE)
    
    tif_path = file.path(Country_dir, paste0(tif_name, ".tif"))
    
    # Crop (and mask) CLC by site polygon and save to geotiff
    # This will be a multiband raster, with four bands:
    # 2000, 2006, 2012, 2018
    clc_cut = mask(crop(clc, site), vect(site),
                   filename = tif_path, overwrite = TRUE)
  })
})
