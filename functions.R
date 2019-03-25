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