packages <- c('rgdal', # for geopackage
              'sf' # for geopackage
)

pkg_notinstall <- packages[!(packages %in% installed.packages()[,"Package"])]
lapply(pkg_notinstall, install.packages, dependencies = TRUE)
lapply(packages, library, character.only = TRUE)

las <- read.csv("../data/places_la_to_country.csv") # las to extract names etc. from

geo_data <- st_read("../data/bdline_gb.gpkg", layer = "district_borough_unitary") # extract layer of interest
geo_geom <- geo_data$geometry # get geometry columns
geo_geom_wgs84 <- st_transform(geo_geom, crs = "WGS84") # tranform to longitude/latitude
names(geo_geom_wgs84) <- geo_data$Name # add names

geo_geom_wgs84_2 <- vector(mode = "list", length = length(geo_geom_wgs84))
names(geo_geom_wgs84_2) <- geo_data$Name # add names

for(i in 1:length(geo_geom_wgs84)){
  for(j in 1:length(geo_geom_wgs84[[i]])){
    # for each LA, create just one list of lists that contains all coordinate pair lists
    # so that for LAs with multiple coordinate lists, each LA has a separate df for each list of coords
    geo_geom_wgs84_2[[i]][["coords"]][[j]] <- as.data.frame(geo_geom_wgs84[[i]][[j]][[1]])
    colnames(geo_geom_wgs84_2[[i]][["coords"]][[j]]) <- c("long","lat")
    
  }
  
  geo_geom_wgs84_2[[i]][["census_code"]] <- geo_data$Census_Code[i] # take census code
  
  # add la, county, region, and country names
  try(
    geo_geom_wgs84_2[[i]][["la"]] <- las[which(las$LAD19CD == geo_data$Census_Code[i]), "LAD19NM"] 
  )
  try(
    geo_geom_wgs84_2[[i]][["county"]] <- las[which(las$LAD19CD == geo_data$Census_Code[i]), "CTY19NM"]
  )
  try(
    geo_geom_wgs84_2[[i]][["region"]] <- las[which(las$LAD19CD == geo_data$Census_Code[i]), "RGN19NM"]
  )
  try(
    geo_geom_wgs84_2[[i]][["country"]] <- las[which(las$LAD19CD == geo_data$Census_Code[i]), "CTRY19NM"]
  )
  
  # report which LAs have missing values 
  if(is_empty(geo_geom_wgs84_2[[i]][["la"]])){
    print(paste0(names(geo_geom_wgs84_2)[i], " la missing (", i, ")"))
  }
  if(is_empty(geo_geom_wgs84_2[[i]][["county"]])){
    print(paste0(names(geo_geom_wgs84_2)[i], " county missing (", i, ")"))
  }
  if(is_empty(geo_geom_wgs84_2[[i]][["region"]])){
    print(paste0(names(geo_geom_wgs84_2)[i], " region missing (", i, ")"))
  }
  if(is_empty(geo_geom_wgs84_2[[i]][["country"]])){
    print(paste0(names(geo_geom_wgs84_2)[i], " country missing (", i, ")"))
  }
  # rename las with names from list from gov website
  try(
    names(geo_geom_wgs84_2)[i] <- geo_geom_wgs84_2[[i]][["la"]]
  )
}

# manually add missing values

geo_geom_wgs84_2[["West Northamptonshire"]][["la"]] <- "West Northamptonshire"
geo_geom_wgs84_2[["West Northamptonshire"]][["region"]] <- "East Midlands"
geo_geom_wgs84_2[["West Northamptonshire"]][["country"]] <- "England"

geo_geom_wgs84_2[["North Northamptonshire"]][["la"]] <- "North Northamptonshire"
geo_geom_wgs84_2[["North Northamptonshire"]][["region"]] <- "East Midlands"
geo_geom_wgs84_2[["North Northamptonshire"]][["country"]] <- "England"

geo_geom_wgs84_2[["Buckinghamshire"]][["la"]] <- "Buckinghamshire"
geo_geom_wgs84_2[["Buckinghamshire"]][["region"]] <- "South East"
geo_geom_wgs84_2[["Buckinghamshire"]][["country"]] <- "England"

coords <- geo_geom_wgs84_2
rm(geo_geom_wgs84_2)
rm(geo_geom_wgs84)
rm(geo_geom)
rm(geo_data)

save(coords, file = "../data/la_coordinate_list.Rdata")