# App backend for scratch logs

# Change date selection for appropriate table
updateDateRangeInput(session = session, inputId = "dates",
                     start = as_tibble(dbGetQuery(db, "SELECT MIN(day) FROM scratch"))$`MIN(day)`,
                     end = as_tibble(dbGetQuery(db, "SELECT MAX(day) FROM scratch"))$`MAX(day)`)

# Plot scratch data
# Render plots 
output$quotas <- renderPlot({
  # Get dates
  start_date <- input$dates[1]
  end_date <- input$dates[2]
  
  # Get the data ready to plot
  plt_data <- as_tibble(dbGetQuery(db, "SELECT scratch, user, day FROM scratch")) %>% 
    mutate(day = as.Date(day, format="%Y-%m-%d")) %>% 
    filter(user %in% input$scratch) %>% 
    filter(day >= start_date & day <= end_date)
  plt_title <- input$scratch
  
  # Convert from bytes to selected unit
  unit_exp <- match(input$units, unit_choices)
  plt_data <- plt_data %>% mutate(scratch = scratch / 1000^unit_exp)
  
  # Plot the data as a time series
  ggplot(data = plt_data) + 
    geom_line(mapping = aes(x = day, y = scratch)) +
    labs(x = "Date", y = input$units) +
    ggtitle(paste(plt_title, "Storage Usage Over Time", sep = " - "))
})