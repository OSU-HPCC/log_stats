# Collection of functions that parse
# data in log files and create a tibble
# from the data. Each function corresponds
# to a different type of log file.

library("tidyverse")

# Scratch usage
scratch <- function(log_file){
  # Remove lines with `du` errors
  log_file <- gsub("du: .*", "du", log_file)
  log_file <- log_file[-which(log_file %in% "du")]
  
  # Strip out first line
  log_file <- log_file[2:length(log_file)]
  
  # Convert to CSV format
  log_file <- gsub("\\s+", ",", log_file)
  
  # Create a tibble from the data
  # user_quotas
  scratch = vector()
  user = vector()
  for (entry in log_file){
    scratch = c(scratch, unlist(strsplit(entry, ","))[1])
    user = c(user, unlist(strsplit(entry, ","))[2])
  }
  scratch_usage <- tibble(scratch, user)
  
  # Convert units
  scratch_usage <- scratch_usage %>% mutate(scratch = convertunits(scratch))
  
  # Return tibble
  return(scratch_usage)
}

# Project usage
project <- function(log_file, filename){
  # Get project box number
  log_projbox <- gsub("[[:digit:]]*project", "", filename)
  log_projbox <- gsub("quotalog.txt", "", log_projbox) %>% as.integer()
  
  # Extract log info 
  log_file <- gsub("Project quota on.*", "Project quota on", log_file)
  start_project_quotas <- match("Project quota on", log_file)
  project_quotas <- log_file[start_project_quotas:length(log_file)]
  
  # Remove headers
  project_quotas <- project_quotas[-(1:4)]
  
  # Convert to CSV format
  project_quotas <- gsub("\\s+", ",", project_quotas)
  
  # Create a tibble from the data
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
  
  # Convert units
  project_quotas <- project_quotas %>% mutate(used = convertunits(used),
                                              soft = convertunits(soft),
                                              hard = convertunits(hard))
  
  # Add column to designate storage box
  project_quotas <- project_quotas %>% mutate(projbox = log_projbox)
  
  # Return a tibble with the log data
  return(project_quotas)
}

# Project usage by user
project_users <- function(log_file, filename){
  # Get project box number
  log_projbox <- gsub("[[:digit:]]*project", "", filename)
  log_projbox <- gsub("quotalog.txt", "", log_projbox) %>% as.integer()
  
  # Extract log info 
  log_file <- gsub("Project quota on.*", "Project quota on", log_file)
  log_file <- gsub("User quota on.*", "User quota on", log_file)
  start_user_quotas <- match("User quota on", log_file)
  start_project_quotas <- match("Project quota on", log_file)
  user_quotas <- log_file[start_user_quotas:(start_project_quotas-2)]
  
  # Remove headers
  user_quotas <- user_quotas[-(1:4)]
  
  # Convert to CSV format
  user_quotas <- gsub("\\s+", ",", user_quotas)
  
  # Create a tibble from the data
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
  
  # Convert units
  user_quotas <- user_quotas %>% mutate(used = convertunits(used),
                                        soft = convertunits(soft),
                                        hard = convertunits(hard))
  
  # Add column to designate storage box
  user_quotas <- user_quotas %>% mutate(projbox = log_projbox)
  
  # Return a tibble with the log data
  return(user_quotas)
}