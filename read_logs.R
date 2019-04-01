library("tidyverse")
library("RSQLite")
source("functions.R")

# Lists of log information
log_types <- c("scratch", "project", "project_users")
# Patterns for getting list of files
file_patterns <- list(scratch = "[[:digit:]]*scratchuse", 
                  project = "[[:digit:]]*project[[:digit:]][[:digit:]]quotalog.txt",
                  project_users = "[[:digit:]]*project[[:digit:]][[:digit:]]quotalog.txt")
# Patterns for extracting dates from filenames
file_date <- list(scratch = "scratchuse",
                  project = "project[[:digit:]][[:digit:]]quotalog.txt",
                  project_users = "project[[:digit:]][[:digit:]]quotalog.txt")

# Get list of log filenames, types, and dates for each type of log
log_files <- tibble(filename = character(), log_type = character(), day = date())
for(type in log_types){
  log_files <- log_files %>% add_row(filename = dir(path = "./logs/", 
                                                    pattern = as.character(file_patterns[type])),
                                     log_type = type,
                                     day = gsub(file_date[type], "", filename) %>% 
                                       as.Date(format = "%Y%m%d") %>% 
                                       format("%Y-%m-%d"))
}
log_files <- log_files %>% mutate(day = as.Date(day, format = "%Y-%m-%d"))

# Open database connection
db = dbConnect(SQLite(), dbname="logs.db")

# Read the database and remove filesnames that
# have already been entered into the database
for(type in log_types){
  already_there <- already_dates(db, type)
  log_files <- log_files %>% filter(!(log_type ==  type & (day %in% already_there$day)))
}

# Write new files to appropriate tables in database
if(dim(log_files)[1] == 0){
  for(row in 1:nrow(log_files)){
    write_log(db, log_files[row,])
  }
}

# Close database connection
dbDisconnect(db)
