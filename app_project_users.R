# App backend for projects by user

# Change date selection for appropriate table
updateDateRangeInput(session = session, inputId = "dates",
                     start = as_tibble(dbGetQuery(db, "SELECT MIN(day) FROM project_users"))$`MIN(day)`,
                     end = as_tibble(dbGetQuery(db, "SELECT MAX(day) FROM project_users"))$`MAX(day)`)

# Plot project data by user
# Render plots 
output$quotas <- renderPlot({
  # Get dates
  start_date <- input$dates[1]
  end_date <- input$dates[2]
  
  # Get the data ready to plot
  plt_data <- as_tibble(dbGetQuery(db, "SELECT user, used, day FROM project_users")) %>% 
    mutate(day = as.Date(day, format="%Y-%m-%d")) %>% 
    filter(user %in% input$selectUsers) %>% 
    filter(day >= start_date & day <= end_date)
  plt_title <- input$selectUsers
  
  # Convert from bytes to selected unit
  unit_exp <- match(input$units, unit_choices)
  plt_data <- plt_data %>% mutate(used = used / 1000^unit_exp)
  
  # Plot the data as a time series
  ggplot(data = plt_data) + 
    geom_line(mapping = aes(x = day, y = used)) +
    labs(x = "Date", y = input$units) +
    ggtitle(paste(plt_title, "Storage Usage Over Time", sep = " - "))
})