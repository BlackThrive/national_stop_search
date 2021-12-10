# Jolyon Miles-Wilson
# 10/12/2021

# Acquire Stop and Search data for a list of Local Authority (LA) areas over a 
# time period. 

# Arguments

## coord_list: List of areas of interest. Each element of list must be a data 
## frame with column names "lat" and "long". A separate function is available
## to create this list.

## most_recent_month: Numeric value specifying most recent month (e.g., 8 for August)

## most_recent_year (YYYY): Numeric value specifying most recent year (e.g., 2021)

## If one or both of most_recent_month/year is not specified, the function will 
## query Police API for the most recent update and use this as a start point.

## num_months_backwards: Number of months backwards for which data are required. 

## wait_time: Number of seconds to wait between retries of unsuccessful requests.

## max_tries: Maximum number of retries following an unsuccessful request. Default 
## is 'Inf' because usually all data are desired and unsuccessful requests are most
## likely timeouts that can be resolved by retrying.

# Value

## Output is a list containing 'results' and 'missing_entries'. 'results' contains
## the queried data in a dataframe. 'missing_entries' contains a list of LAs and
## their corresponding index in coord_list for which no data records exist for
## the specified time period.

# Required packages (will be installed and libraried on run):
packages <- c('httr' # for http requests
              )

pkg_notinstall <- packages[!(packages %in% installed.packages()[,"Package"])]
lapply(pkg_notinstall, install.packages, dependencies = TRUE)
lapply(packages, library, character.only = TRUE)

la_search_police_api <- function(coord_list, 
                                 most_recent_month = NULL, 
                                 most_recent_year = NULL, 
                                 num_months_backwards = 12, 
                                 wait_time = 5, 
                                 max_tries = Inf){
  # initialise dataframes
  overall_output <- data.frame()
  no_entries_df <- data.frame(setNames(rep(list(NA), 2), c("Index","Name")))
  
  # h loop iterates over LAs
  for(h in 1:length(coord_list)){
    print(paste0("Started area ", h)) # report start (useful for debugging)
    
    la <- coord_list[[h]][["la"]] # LA name
    
    county <- coord_list[[h]][["county"]] # county name
    if(is_empty(county)){
      county <- NA # set NA if missing
    }
    
    region <- coord_list[[h]][["region"]] # region name
    if(is_empty(region)){
      region <- NA # set NA if missing
    }
    
    country <- coord_list[[h]][["country"]] # country name
    
    # get most recent update if most_recent data not specified
    if(is.null(most_recent_month) || is.null(most_recent_year)){ 
      # get most recent update from API:
      date <- httr::content(
        httr::GET("https://data.police.uk/api/crimes-street-dates"))[[1]][["date"]] 
      most_recent_month <- as.numeric(substr(date,6,7))
      most_recent_year <- as.numeric(substr(date,1,4))
    }
    else{
      most_recent_month <- most_recent_month
      most_recent_year <- most_recent_year
    }
    
    area_output <- data.frame() # initialise area output df
    
    # i loop iterates over the months required 
    for(i in 1:num_months_backwards){
      # format date to what is needed for API query ("yyyy-mm")
      if(i == 1){ # set values for first iteration
        month_num <- most_recent_month
        year <- most_recent_year
      }
      else{ # subsequent iterations
        month_num <- month_num - 1 # backwards a month each iteration
        if(month_num %% 12 == 0){ # if reach a new year, start months from 12 again
          month_num <- 12
          year <- year - 1 # backwards a year
        }
      }
      if(month_num < 10){ # paste 0 for months lower than 10
        month <- paste("0", month_num, sep = "")
      }
      else{
        month <- month_num
      }
      
      date <- paste(year, "-", month, sep = "") # combine dates into one string
      
      # j loop iterates over the coordinate sets within each LA and creates a
      # polygon string to be searched, and then submits the query.
      # Most LAs have only one coordinate set, but some have multiple (e.g., 
      # those that include islands). The function therefore needs to search 
      # each coordinate set within a LA separately.
      coord_string <- c() # initialise vector for coord string
      for(j in 1:length(coord_list[[h]][["coords"]])){
        # set this iteration's coordinate set:
        area_coords <- coord_list[[h]][["coords"]][[j]]
        # combine coord strings into format required by API:
        coord_string <- paste0(area_coords$lat,",",area_coords$long, collapse = ":") 
        
        # create body for post request
        body <- list("poly" = coord_string,
                     "date" = date)
        # search API for this coordinate set and date:
        post_request <- httr::POST("https://data.police.uk/api/stops-street?", body = body)
        
        # if search quota reached, break (shouldn't be an issue but just in case)
        if(post_request[["status_code"]] == 429){
          print("Quota reached. Abandoning request.")
          break
        }
        else{
          # if the request didn't succeed, wait some time ('wait_time') and 
          # keep trying up until 'max_tries' attempts.
          attempt <- 1
          while(post_request[["status_code"]] != 200 && attempt <= max_tries){ 
            print(paste0("Server error. Trying again (", attempt,")"))
            Sys.sleep(wait_time) # wait some time before trying again
            try(
              post_request <- httr::POST("https://data.police.uk/api/stops-street?", body = body)
            )
            # if search quota reached, break (shouldn't be an issue but just in case)
            if(post_request[["status_code"]] == 429){ 
              print("Quota reached. Abandoning request.")
              break
            }
            attempt <- attempt + 1
          }
        }
        
        # get data from results of query
        df <- httr::content(post_request) 
        # unlist data and convert to dataframe:
        df_2 <- lapply(df, unlist)
        df_3 <- do.call(bind_rows, df_2)
        df_3$coord_set <- j # record which coordinate set data is from
        
        # add results of this coordinate set iteration (j) to the output for 
        # this LA iteration (h). Use bindrows for (high) possibility that columns
        # from different iterations will be in different order/missing
        area_output <- bind_rows(area_output, df_3) 
        
        cat("\014") # clear console 
        # report overall (i.e., LA) progress
        print(paste0("Working... LA ", h, " of ", length(coord_list), 
                     " (", 
                     round(100 * (h / length(coord_list)), 2), "%)"))
        # report month progress
        print(paste0("Working... Month ", i, " of ", num_months_backwards, 
                     " (", date, ")"))
        # report coordinate set progress
        print(paste0("Working... ", j, " of ", 
                     length(coord_list[[h]][["coords"]]), 
                     " coordinate sets retrieved"))

        
      } # coordinate set loop (j) ends
      

      
    } # month loop (i) ends
    
    # If there were no records for this LA, record the LA iteration number
    # and name, then proceed to the next LA
    if(nrow(area_output) == 0){
      if(is.na(no_entries_df[1,1])){ # if first occurrence, replaces NAs 
        no_entries_df[1,] <- c(h, la)
      }
      else{ # rbind subsequent occurrences
        no_entries_df <- rbind(no_entries_df, c(h, la))        
      }
      print(paste0("No records for ", la))
      next # proceed to next LA
    }
    
    # add columns for LA name, county, region, country, and the iteration index
    # for the LA (useful for quickly identifying which LA the function reached 
    # if it breaks unexpectedly)
    area_output$la <- la
    area_output$county <- county
    area_output$region <- region
    area_output$country <- country
    area_output$index <- h
    
    # move index and location data to front of df
    area_output <- area_output %>%
      select(index, la, county, region, country, everything())
    overall_output <- bind_rows(overall_output, area_output)
  
    # create a temporary output list and save it every time a LA completes, so
    # that there is a backup in case function breaks. Saves to same folder as
    # script
    save_progress <- list(result = overall_output,
                          missing_entries = no_entries_df)
    save(save_progress, file = "./save_progress.Rdata")
  } # LA loop (h) ends
  
  # return output. 'result' is the data. 'missing_entries' provides a list of
  # LAs that are missing from the data because there were no records for the 
  # LA in the specified time period.
  return(list(result = overall_output,
              missing_entries = no_entries_df))
}
