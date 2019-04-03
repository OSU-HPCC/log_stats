# App backend for project log data

# Change date selection for appropriate table
updateDateRangeInput(session = session, inputId = "dates",
                     start = as_tibble(dbGetQuery(db, "SELECT MIN(day) FROM project"))$`MIN(day)`,
                     end = as_tibble(dbGetQuery(db, "SELECT MAX(day) FROM project"))$`MAX(day)`)