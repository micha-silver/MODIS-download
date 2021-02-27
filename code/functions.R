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



TimeSeriesFromRasters = function(site) {
  # Get list of RData files saved in above code
  # Each is contains a rasterStack
  # Load each and calculate cell statistics: mean and std dev.
  # For each time slot
  
  # Read in site polygon to clip raster 
  site_gpkg = file.path(GIS_dir, paste0(site, ".gpkg"))
  site_sf = sf::read_sf(site_gpkg)
  site_dir = file.path(Output_dir, site)
  rdata_paths = list.files(site_dir, pattern=".RData$",
                         recursive=TRUE, full.names=TRUE)
  
  timeseries_list = list()
  for (rd in 1:length(rdata_paths)) {
    load(rdata_paths[rd])
    # The object in the RData file was saved as "raster_ts"
    # First, keep list of raster dates
    raster_ts_dates = raster_ts@z$time
    
    # Which MODIS data product is this:
    # Split the name to get product
    prod = unlist(strsplit(names(raster_ts)[1],
                    split="_", fixed=TRUE))
    # Drop the year and DOY components
    prod = prod[1:(length(prod) - 2)]
    prod = paste(prod, collapse = "_")
    
    # Now mask out raster by site polygon
    # First transform site polygon to raster CRS
    site_sf = st_transform(site_sf, crs = st_crs(raster_ts))
    raster_ts = mask(raster_ts, site_sf)
    
    # Rescale raster values, based on how data are stored in MODIS
    if (grepl(pattern = "LST", x = prod)) {
      # LST in MODIS are Kelvin degrees * 50
      # Revert to Celsius by dividing by 50 and subtracting 273
      raster_ts = raster_ts * 0.02 - 273.15
    } else if (grepl(pattern = "NDVI", x = prod)) {
      # VI values in MODIS are scaled up by 10000
      raster_ts = raster_ts * 0.0001
    }

    vals_mean = cellStats(raster_ts, "mean")
    vals_sd = cellStats(raster_ts, "sd")
    vals_df = data.frame(vals_mean, vals_sd, raster_ts_dates)
    names(vals_df) = c(paste0("Mean_", prod),
                       paste0("StdDev_", prod),
                       "Date")
    timeseries_list[[rd]] = vals_df
    names(timeseries_list)[rd] = prod
  }
  return(timeseries_list)
}


PlotTimeSeries = function(timeseries_list, site) {
  # Prepare directory to save time series graphs
  Figures_site = file.path(Figures_dir, site)
  if (!dir.exists(Figures_site)) {
      dir.create(Figures_site, recursive = TRUE)}

  # Loop over items in timeseries list, create plot for each product
  plt_list = lapply(1:length(timeseries_list),
                FUN = function(t) {
    # Work on one product, and get rid of NAs
    df = timeseries_list[[t]]
    df = df[complete.cases(df),]
    # Pivot to long data.frame for easy plotting
    df2 = pivot_longer(df, -Date,
                       names_to = "Statistic",
                       values_to = "Value")
    prod = names(timeseries_list)[t]
    
    # Save each timeseries to CSV
    csv_file = paste(prod, "timeseries.csv", sep="_")
    csv_path = file.path(Figures_site, csv_file)
    write.csv(df, file = csv_path,row.names = FALSE)
    
    pl = ggplot(data = df2) +
      geom_line(aes(x=Date, y=Value, color = Statistic),
                size = 0.6, alpha=0.7 ) + 
      geom_point(aes(x=Date, y=Value, color = Statistic),
                 size = 0.6, alpha=0.5 ) + 
      #scale_color_manual(values = clrs) +
      ggtitle(paste(site, prod)) +
       theme(axis.text = element_text(size=10),
             axis.title = element_text(size=12),
             title = element_text(size=12, face="bold"))
    #print(pl)
    return(pl)
  })

  # Plot all MODIS products in one figure
  pg = cowplot::plot_grid(plotlist = plt_list,
                          align = "v", ncol=1)
  # save merged plot
  png_file = paste(site, "timeseries_plots.png", sep="_")
  png_path = file.path(Figures_site, png_file)
  save_plot(png_path, pg, ncol=1, base_height = 9.0, base_asp = 1)
}

CropSaveCorine = function(site) {
  # Corine Landcover have been downloaded in advance from
  # https://land.copernicus.eu/pan-european/corine-land-cover
  # (Requires registration)
  CLC_dir = file.path(GIS_dir, "CLC")
  site_gpkg = file.path(GIS_dir, paste0(site, ".gpkg"))
  site_sf = sf::read_sf(site_gpkg)
  site_dir = file.path(Output_dir, site)
  clc_list = list.files(CLC_dir, pattern = ".tif$",
                        full.names = TRUE)
  
  # Prepare directory to save cropped CLC rasters
  Output_clc = file.path(Output_dir, site, "CLC")
  if (!dir.exists(Output_clc)) {dir.create(Output_clc,
                                           recursive = TRUE)}
  for (clc_tif in clc_list) {
    # Get Year for this CLC file
    clc_name = tools::file_path_sans_ext(basename(clc_tif))
    clc_yr = unlist(strsplit(clc_name, split = "_",
                             fixed = TRUE))[2]
    
    clc = read_stars(clc_tif)
    # Crop to site bounding box (after transform to CLC coord system)
    site_sf = st_transform(site_sf, st_crs(clc))
    clc_crop = clc[site_sf,]
 
    Output_path = file.path(Output_clc, paste0(site, clc_yr, ".tif"))
    write_stars(obj = clc_crop, dsn = Output_path)
  }
}
