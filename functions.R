library("tidyverse")
library("RSQLite")

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

# Function for reading log file and writing 
# its contents to the database
write_log <- function(db, logfile){
  # Read in log file
  log_file <- readLines(logfile)
  
  # Get log file time stamp
  log_date <- gsub("project[[:digit:]][[:digit:]]quotalog.txt", "", logfile) %>% 
    as.Date(format = "%Y%m%d")
  
  # Get project box number
  log_projbox <- gsub("[[:digit:]]*project", "", logfile)
  log_projbox <- gsub("quotalog.txt", "", log_projbox) %>% as.integer()
  
  # Get the starting positions of the two logs
  log_file <- gsub("Project quota on.*", "Project quota on", log_file)
  log_file <- gsub("User quota on.*", "User quota on", log_file)
  start_user_quotas <- match("User quota on", log_file)
  start_project_quotas <- match("Project quota on", log_file)
  
  # Split out the two logs
  user_quotas <- log_file[start_user_quotas:(start_project_quotas-2)]
  project_quotas <- log_file[start_project_quotas:length(log_file)]
  
  # Remove old headers
  user_quotas <- user_quotas[-(1:4)]
  project_quotas <- project_quotas[-(1:4)]
  
  # Convert to CSV format
  user_quotas <- gsub("\\s+", ",", user_quotas)
  project_quotas <- gsub("\\s+", ",", project_quotas)
  
  # Create a tibble from the data
  # user_quotas
  user = vector()
  used = vector()
  soft = vector()
  hard = vector()
  warn = vector()
  grace = vector()
  for (entry in user_quotas){
    user = c(user, unlist(strsplit(entry, ","))[1])
    used = c(used, unlist(strsplit(entry, ","))[2])
    soft = c(soft, unlist(strsplit(entry, ","))[3])
    hard = c(hard, unlist(strsplit(entry, ","))[4])
    warn = c(warn, unlist(strsplit(entry, ","))[5])
    grace = c(grace, unlist(strsplit(entry, ","))[6])
  }
  user_quotas <- tibble(user, used, soft, hard, warn, grace)
  # project_quotas
  user = vector()
  used = vector()
  soft = vector()
  hard = vector()
  warn = vector()
  grace = vector()
  for (entry in project_quotas){
    user = c(user, unlist(strsplit(entry, ","))[1])
    used = c(used, unlist(strsplit(entry, ","))[2])
    soft = c(soft, unlist(strsplit(entry, ","))[3])
    hard = c(hard, unlist(strsplit(entry, ","))[4])
    warn = c(warn, unlist(strsplit(entry, ","))[5])
    grace = c(grace, unlist(strsplit(entry, ","))[6])
  }
  project_quotas <- tibble(project = user, used, soft, hard, warn, grace)
  
  # Add date column
  user_quotas <- user_quotas %>% mutate(day = format(log_date, "%Y-%m-%d"))
  project_quotas <- project_quotas %>% mutate(day = format(log_date, "%Y-%m-%d"))
  
  # Convert units
  user_quotas <- user_quotas %>% mutate(used = convertunits(used),
                                        soft = convertunits(soft),
                                        hard = convertunits(hard))
  project_quotas <- project_quotas %>% mutate(used = convertunits(used),
                                              soft = convertunits(soft),
                                              hard = convertunits(hard))
  
  # Add column to designate storage box (flesh this out later)
  user_quotas <- user_quotas %>% mutate(projbox = log_projbox)
  project_quotas <- project_quotas %>% mutate(projbox = log_projbox)
  
  # Write data to database
  dbWriteTable(conn = db, name = "user_quotas", user_quotas, append = T, row.names = F)
  dbWriteTable(conn = db, name = "project_quotas", project_quotas, append = T, row.names = F)
}