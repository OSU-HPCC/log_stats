# App backend for projects by user

# Change date selection for appropriate table
updateDateRangeInput(session = session, inputId = "dates",
                     start = as_tibble(dbGetQuery(db, "SELECT MIN(day) FROM project_users"))$`MIN(day)`,
                     end = as_tibble(dbGetQuery(db, "SELECT MAX(day) FROM project_users"))$`MAX(day)`)