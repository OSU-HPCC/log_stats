# App backend for scratch logs

# Change date selection for appropriate table
updateDateRangeInput(session = session, inputId = "dates",
                     start = as_tibble(dbGetQuery(db, "SELECT MIN(day) FROM scratch"))$`MIN(day)`,
                     end = as_tibble(dbGetQuery(db, "SELECT MAX(day) FROM scratch"))$`MAX(day)`)