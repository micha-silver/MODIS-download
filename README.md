Acquiring EO datasets for eLTER+ sites
================

Micha Silver, Arnon Karnieli

Remote Sensing Lab, Sde Boker Campus, Ben Gurion University

28/02/2021


## Data

These `R` scripts demonstrate acquiring a time series of EO datasets
covering five eLTER sites. Each demo consists of four parts:

1.  Setup of the environment, including loading `R` libraries, defining
    directories, and reading in shapefiles of the eLTER sites.
2.  Choosing and downloading of the desired datasets, then
    cropping to the bounding box of each site.
3.  For MODIS, calculating averages of each product over the area of the
    sites, and preparing a time series these averages covering 10 years
    of MODIS products for each site.
4.  Visualizing a sample of the results

The data outputs from these scripts are available from the UK Centre for Ecology and Hydrology (UKCEH) Datalabs environment at:

https://datalab.datalabs.ceh.ac.uk/projects/elterfr/storage

Output data are stored in the following directory structure:

  - *GIS*: contains polygon layers for each site, and the Corine rasters
    covering Europe for four years.
  - *Output*: contains a directory for each site, with all NDVI, and LST
    rasters (GeoTiff format) covering 10 years. Within each site
    directory there is also a subdirectory Time\_Series which contains
    the time series averages as a raster stack (in RData format).
  - *Documents*: contains relevant documentation (as well as this file)
  - *Figures*: contains the time series plots, and data files (csv) for
    each site.


## Code

  * See [download_MODIS](code/download_MODIS.md) for explanations and examples of how to obtain MODIS (low resolution) NDVI and LST data.

  * See [download_ODS](code/download_ODS.md) for an example of obtaining high resolution NDVI from OpenDataScience

The `R` code and functions to run this demo are available on github at:
<https://github.com/micha-silver/MODIS-download>

