# Helper functions

ObtainSitePolygons = function(site_list_file) {
  # Download shapefile from DEIMS website
  # Useing list of sites/URLs in text file
  # Collect into one sf object
  # Save to gpkg
  site_list = read.csv(site_list_file)
  sites_sf_list = lapply(1:length(site_list$url), function(s) {
    site_name = site_list$site_name[s]
    site_url = site_list$url[s]
    dest_zip = file.path(GIS_dir, paste0(site_name, ".zip"))
    download.file(site_url,destfile = dest_zip)
    unzip(dest_zip, exdir = GIS_dir)
    site_shp = file.path(GIS_dir, "deims_sites_boundariesPolygon.shp")
    site_sf = read_sf(site_shp)
    file.remove(list.files(GIS_dir,
                           pattern = "deims_",
                           full.names = TRUE))
    site_gpkg = file.path(GIS_dir, paste0(site_name,".gpkg"))
    write_sf(site_sf, site_gpkg)
  })
}


DateFromFilename = function(f) {
  # Split file name at '_', and use last two elements to construct date
  parts = unlist(strsplit(basename(f),
                          split =  "_", fixed = TRUE))
  yr = parts[length(parts)-1]
  doy = gsub(x = parts[length(parts)], pattern = ".tif", replacement = "")
  dt = as_date(paste(yr, doy, sep="-"), format = "%Y-%j")
  return(dt)
}


DatesFromFolder = function(folder) {
  # Get list of dates from file names
  file_list = list.files(path = folder,
                         pattern = "*.tif$",
                         full.names = TRUE)
  dates = as_date(sapply(file_list, DateFromFilename, USE.NAMES = FALSE),
                  origin = "1970-01-01")
  # return as data.frame
  return(data.frame("Date" = dates))
}


StarsFromFolder = function(folder, site, modis_type = "NDVI") {
  # Scan all files in folder into a stars object,
  file_list = list.files(path = file.path(folder, modis_type),
                         pattern = "*.tif$",
                         full.names = TRUE)
  
  # Read all files into a stars object with 3 dimensions
  # Using along=... to set the third dim to dates (YYYY_DOY format)
  doy_names = unlist(lapply(file_list, FUN = function(f) {
    dn1 = gsub(x = basename(f), pattern = ".tif", replacement = "")
    parts = unlist(strsplit(x = dn1, split = "_", ))
    return(paste("DOY",
                 parts[length(parts)-1],
                 parts[length(parts)], sep="_"))
  }))
  mod_stars = read_stars(file_list, along = list(DOY = doy_names))
  # and clip to the site polygon
  mod_stars = mod_stars[site]
  return(mod_stars)  
}


ValuesFromStars = function(mod_stars, modis_type = "NDVI") {
  # Use st_apply to get mean for each DOY
  if (grepl(pattern = "LST", x = modis_type)) {
    # LST in MODIS are Kelvin degrees * 50
    # Revert to Celsius by dividing by 50 and subtracting 273
    mod_stars[[1]] = mod_stars[[1]] * 0.02 - 273.15
    vals = st_apply(mod_stars,
                    MARGIN = "DOY",
                    FUN = mean,
                    na.rm = TRUE)$mean
    vals_sd = st_apply(mod_stars,
                       MARGIN = "DOY",
                       FUN = sd,
                       na.rm = TRUE)$sd  
    if (grepl(pattern = "Day", modis_type)) {
      vals_df = data.frame("LST_Day" = vals,
                           "LST_Day_StdDev" = vals_sd)
    } else {
      vals_df = data.frame("LST_Night" = vals,
                           "LST_Night_StdDev" = vals_sd)
    }
  } else {
    # VI values in MODIS are scaled up by 10000
    mod_stars[[1]] = mod_stars[[1]] * 0.0001
    vals = st_apply(mod_stars,
                    MARGIN = "DOY",
                    FUN = mean,
                    na.rm = TRUE)$mean
    vals_sd = st_apply(mod_stars,
                       MARGIN = "DOY",
                       FUN = sd,
                       na.rm = TRUE)$sd
    if (grepl("NDVI", modis_type)) {
      vals_df = data.frame("NDVI" = vals, "NDVI_StdDev" = vals_sd)  
    } else {
      vals_df = data.frame("EVI" = vals, "EVI_StdDev" = vals_sd)
    }
  }
  return(vals_df)
}


PixelCountFromStars = function(mod_stars) {
  names(mod_stars) = "Value"
  # Use st_apply to extract count of non-NA pixels
  # cnt_pixels = function(s, na.rm = TRUE, ...) {
  #   # Count number of non NA values in $Value attrib
  #   sdf = as.data.frame(s)
  #   if (na.rm) {
  #     sdf = sdf[complete.cases(sdf),]
  #   }
  #   return(length(sdf$Value)) 
  # }
  cnt_pixels <- function(s) { sum(!is.na(s)) }
  cnt = st_apply(mod_stars,
                 MARGIN = "DOY",
                 FUN = cnt_pixels)$cnt_pixels
  # Return as data.frame
  return(data.frame("Num_Pixels" = cnt))
}


PixelCountFromFolder = function(folder, site) {
  # How many pixels have values in this site
  file_list = list.files(path = folder,
                         pattern = ".*tif$",
                         full.names = TRUE)
  
  #read each file into raster, and use extract to get non-NA pixels 
  cnt = sapply(file_list,
               FUN = function(f) {
                 # Use only the Aqua files to avoid duplicate counts
                 if (grepl("MOD", f)) {
                   c=NA
                 } else {
                   r=raster(f)
                   c = raster::extract(r, site,
                                       fun=function(x, ...) length(na.omit(x)))
                 }
                 return(c)
               },
               USE.NAMES = FALSE)
  return(data.frame("Num_Pixels" = cnt))
}


PlotSave = function(site_name, df, modis_type = "VI") {
  # Get rid of NAs
  df = df[complete.cases(df),]
  
  # Save to CSV
  csv_file = paste(site_name, modis_type, "data.csv", sep="_")
  Output_csv_path = file.path(Output_dir, site_name, csv_file)
  write.csv(df, file = Output_csv_path)
  
  # Prepare to save Plot
  png_file = paste(site_name, modis_type, "plot.png", sep="_")
  Output_png_path = file.path(Output_dir, site_name, png_file)
  # Pivot wide to long format for plotting 
  df2 = df %>% 
    # Get only the original values (Not StdDev, or num_pixels)
    dplyr::select(., c(1,2,4)) %>%
    pivot_longer(., cols = c(-Date), 
                 names_to = "Type", values_to = "Value")
  if (modis_type == "VI") {
    clrs = c("darkgreen","blue")
  } else {
    clrs = c("darkred", "purple")
  }
  pl = ggplot(data = df2) +
    geom_line(aes(x=Date, y=Value, color = Type),
              size = 0.3, alpha=0.5 ) + 
    geom_point(aes(x=Date, y=Value, color = Type),
               size = 0.3, alpha=0.5 ) + 
    scale_color_manual(values = clrs) +
    ggtitle(paste(site_name, modis_type)) +
    theme(axis.text = element_text(size=12),
          axis.title = element_text(size=14),
          title = element_text(size=16))
  print(pl)
  ggsave(Output_png_path, plot = pl,
         width = 18, height = 10, units = "cm")
  
  # Column plot of Num_Pixels
  png_file = paste(site_name, modis_type, "num_pixels.png", sep="_")
  Output_png_path = file.path(Output_dir, site_name, png_file)
  pl2 = ggplot(df, aes(x=Date, y=Num_Pixels)) +
    geom_col(alpha=0.4, color = "orange", size = 0.2) +
    ggtitle(paste(site_name, modis_type)) +
    theme(axis.text = element_text(size=12),
          axis.title = element_text(size=14),
          title = element_text(size=16))
  print(pl2)
  ggsave(Output_png_path, plot = pl2,
         width = 18, height = 10, units = "cm")
}

CropSaveCorine = function(clc, clc_path, site, site_name) {
  clc_yr = unlist(strsplit(
    basename(clc_path),split = "_", fixed = TRUE))[2]
  clc_file = paste(site_name, clc_yr, sep="_")
  clc_file = paste0(clc_file, ".tif")
  Output_path = file.path(Output_dir, site_name, "Corine_Landcover")
  if (!dir.exists(Output_path)) dir.create(Output_path)
  Output_clc = file.path(Output_path, clc_file)
  
  clc_crop = clc[site,]
  write_stars(obj = clc_crop, dsn = Output_clc)
}