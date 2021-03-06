Corine Landcover
================
Micha Silver, Arnon Karnieli
29/03/2021

  - [Introduction](#introduction)
  - [Load data](#load-data)
  - [Clip Corine Landcover to site
    boundary](#clip-corine-landcover-to-site-boundary)
  - [Visualization](#visualization)

## Introduction

This script demonstrates “cookie cutting” of Corine landcover maps to
the boundary of chosen eLTER sites

### Libraries

Load required R libraries

``` r
pkg_list = c("terra", "sf",         # Spatial packages
             "tmap", "tmaptools",   # Mapping
             "dplyr", "stringr")    # Code and String manipulation
installed_packages <- pkg_list %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(pkg_list[!installed_packages], dependencies = TRUE)
}
# Packages loading
pkgs = lapply(pkg_list, library, character.only = TRUE)
```

### Define directories

This code chunk defines directories, and output location.

``` r
# Edit below as necessary: GIS, output directories
GIS_dir = "../GIS"
CLC_dir = file.path(GIS_dir, "CLC")

# Where to save outputs
Output_dir = "../Output"
if (!dir.exists(Output_dir)) {dir.create(Output_dir,
                                         recursive = TRUE)}

# (Add option to ignore Datum unknown warnings)
options("rgdal_show_exportToProj4_warnings"="none")
```

## Load data

Now load:

  - the Corine Landcover rasters: four versions, from 2000 to 2018;
  - the DEIMS boundaries shapefile: polygon dataset of eLTER sites
    (contains attribute columns for site name, location and country).

<!-- end list -->

``` r
deims_gpkg = file.path(GIS_dir, "DEIMS_sites.gpkg")
deims = read_sf(deims_gpkg, layer = "sites_eu")

clc_list = list.files(CLC_dir, pattern = ".tif$",
                      full.names = TRUE)

# Read in list of CLC files using terra package
clc = rast(clc_list)
# Reproject deims to match the Corine data
# ETRS 89 LAEA (European) coordinate system, EPSG 3035
deims = st_transform(deims, st_crs(clc))
```

## Clip Corine Landcover to site boundary

In this code chunk, a list of the EU countries is displayed to allow
user to choose her country. Using the chosen country name, a list of the
eLTER sites (from DEIMS: <https://deims.org/search/sites>) is prepared.
Then the `terra` package in R is used to read CLC rasters and two
functions, `crop()` and `mask()` are applied to cookie cut the raster to
each site boundary.

``` r
print(unique(deims$Country))
```

    ##  [1] "Sweden"           "Italy"            "United Kingdom"   "Germany"         
    ##  [5] "Spain"            "Switzerland"      "Czechia"          "Lithuania"       
    ##  [9] "Belgium"          "Portugal"         "Hungary"          "Bulgaria"        
    ## [13] "Romania"          "Austria"          "Poland"           "France"          
    ## [17] "Norway"           "Croatia"          "Latvia"           "Greece"          
    ## [21] "Serbia"           "Slovenia"         "Finland"          "Denmark"         
    ## [25] "Slovakia"         "Turkey"           "Netherlands"      "North Macedonia" 
    ## [29] "Ukraine"          "Poland, Slovakia"

``` r
### Enter country name here:
cntry = "Finland"

deims_country = deims[deims$Country == cntry,]
# For directory name, make sure no wierd characters in country names
cntry = str_replace_all(cntry, "[^[:alnum:]]", "")
Country_dir = file.path(Output_dir, cntry)

if (!dir.exists(Country_dir)) {
  dir.create(Country_dir)
}

# Now do cookie cutting for each site within chosen country
clc_cookiecut = lapply(1:nrow(deims_country), function(s) {
  site = deims_country[s,]
  
  # Prepare file name to save Clipped CLC
  tif_name = paste(str_replace_all(site$Site, "[^[:alnum:]]", ""),
                   str_replace_all(site$Location, "[^[:alnum:]]", ""),
                   str_replace_all(site$Country, "[^[:alnum:]]", ""),
                   sep = "_")
  tif_name = gsub(pattern = "_NA_", replacement = "_",
                  x = tif_name)
  
  tif_path = file.path(Country_dir, paste0(tif_name, ".tif"))
  
  # Crop (and mask) CLC by site polygon and save to geotiff
  # This will be a multiband raster, with four bands:
  # 2000, 2006, 2012, 2018
  clc_cut = mask(crop(clc, site), vect(site),
                 filename = tif_path, overwrite = TRUE)
  
})
# Add site names to clc_cookiecut
names(clc_cookiecut) = deims_country$Site
```

## Visualization

To demonstrate the result, plot one eLTER site from the country list.

``` r
tmap_mode("plot")
```

    ## tmap mode set to plotting

``` r
# Get raster stack and polygon boundary for one site
# Reproject to WGS84 for tmap
clc <- clc_cookiecut[[2]]
clc = project(clc, "epsg:4326")
site <- deims_country[2,]
site = st_transform(site, 4326)

# Color palette prepared from the Corine standard legend:
clc_palette = c("#E6004D", "#FF0000", "#CC4DF2", "#CC0000", "#E6CCCC", "#E6CCE6",
                "#A600CC", "#A64D00", "#FF4DFF", "#FFA6FF", "#FFE6FF", "#FFFFA8",
                "#FFFF00", "#E6E600", "#E68000", "#F2A64D", "#E6A600", "#E6E64D",
                "#FFE6A6", "#FFE64D", "#E6CC4D", "#F2CCA6", "#80FF00", "#00A600",
                "#4DFF00", "#CCF24D", "#A6FF80", "#A6E64D", "#A6F200", "#E6E6E6",
                "#CCCCCC", "#CCFFCC", "#000000", "#A6E6CC", "#A6A6FF", "#4D4DFF",
                "#CCCCFF", "#E6E6FF", "#A6A6E6", "#00CCF2", "#80F2E6", "#00FFA6",
                "#A6FFE6", "#E6F2FF", "#FFFFFF")
clc_labels = c("Continuous urban fabric",
               "Discontinuous urban fabric", "Industrial or commercial units",
               "Road and rail networks and associated land",
               "Port areas", "Airports", "Mineral extraction sites",
               "Dump sites", "Construction sites", "Green urban areas",
               "Sport and leisure facilities", "Non-irrigated arable land", 
               "Permanently irrigated land", "Rice fields", "Vineyards",
               "Fruit trees and berry plantations", "Olive groves", "Pastures",
               "Annual crops associated with permanent crops",
               "Complex cultivation patterns",
               "Land principally occupied by agriculture with significant areas of natural vegetation",
               "Agro-forestry areas", "Broad-leaved forest", "Coniferous forest",
               "Mixed forest", "Natural grasslands", "Moors and heathland",
               "Sclerophyllous vegetation", "Transitional woodland-shrub",
               "Beaches dunes sands", "Bare rocks", "Sparsely vegetated areas", 
               "Burnt areas", "Glaciers and perpetual snow", "Inland marshes",
               "Peat bogs", "Salt marshes", "Salines", "Intertidal flats",
               "Water courses", "Water bodies", "Coastal lagoons", "Estuaries",
               "Sea and ocean", "NODATA")

tm_shape(clc) + 
  tm_raster(palette = clc_palette,
            labels = clc_labels, n = 18,
            legend.show = FALSE, alpha = 0.7) +
tm_shape(site) + 
  tm_borders("black", lwd = 1.5) +
tm_basemap("Esri.WorldShadedRelief")
```

    ## Warning: number of legend labels should be 18

<img src="Corine_cookie_cutting_files/figure-gfm/visualization-1.png" style="display: block; margin: auto;" />
