library("tidyverse")
library("RSQLite")
source("log_readers.R")

# Functions to support scripts

# Function for pulling dates out of the database.
# If there is no database yet, function catches the 
# error and returns a default tibble.
already_dates <- function(db, log_type){
  # Create the proper databse query based on the log type.
  query <- sprintf("SELECT day FROM %s", log_type)
  # Try to pull current dates out of the database.
  # Catch the error if there is no database yet.
  already_there <- tryCatch(expr = { as_tibble(dbGetQuery(db, query)) %>% 
                                     mutate(day = as.Date(day, format = "%Y-%m-%d")) %>% unique() },
                            error = function(e){})
  # No error: Return a dates tibble from SQL query.
  # Error: Return an empty dates tibble.
  if( length(already_there) ){
    return(already_there)
  }else{
    return(tibble(day = c(as.Date(NA))))
  }
}

# Function for converting all units to bytes
convertunits <- function(entry){
  # posible units
  file_sizes <- c("", "K", "M", "G", "T", "P")
  # get the units from the entry
  entry_units <- gsub("(\\d*|\\d*\\.\\d*)", "", entry)
  # get the number from the entry
  entry_number <- as.numeric(gsub("[A-Z]", "", entry))
  # get the exponent to convert to bytes
  exponent <- match(entry_units, file_sizes) - 1
  
  # convert to bytes
  return(entry_number * 1000^exponent)
}

# Function for reading log files and writing 
# their contents to the database
write_log <- function(db, log_info){
  # Read in log file
  log_file <- readLines(sprintf("logs/%s", log_info$filename))
  
  # Read the contents of the log file and
  # create a tibble from its data
  # Log files: scratch usage, project usage, and
  # project usage by users.
  log_data <- switch(log_info$log_type,
                     scratch = scratch(log_file),
                     project = project(log_file, log_info$filename),
                     project_users = project_users(log_file, log_info$filename))
  
  # Add a date column to the tibble
  log_data <- log_data %>% mutate(day = log_info$day %>% format("%Y-%m-%d"))
  
  # Write data to database
  dbWriteTable(conn = db, name = log_info$log_type, log_data, append = T, row.names = F)
}