# App backend for project log data

# Change date selection for appropriate table
updateDateRangeInput(session = session, inputId = "dates",
                     start = as_tibble(dbGetQuery(db, "SELECT MIN(day) FROM project"))$`MIN(day)`,
                     end = as_tibble(dbGetQuery(db, "SELECT MAX(day) FROM project"))$`MAX(day)`)

# Plot data for projects
# Render plots 
output$quotas <- renderPlot({
  # Get dates
  start_date <- input$dates[1]
  end_date <- input$dates[2]
  
  # Prepare data for plotting
  plt_data <- as_tibble(dbGetQuery(db, "SELECT project, used, hard, day FROM project")) %>% 
    mutate(day = as.Date(day, format="%Y-%m-%d")) %>% 
    filter(project %in% input$selectProject) %>% 
    filter(day >= start_date & day <= end_date)
  plt_title <- input$selectProject

  # Gather the data so usage and quota can be plotted together
  # Convert from bytes to selected unit
  unit_exp <- match(input$units, unit_choices)
  plt_data <- gather(plt_data, used:hard, key="QuotavUsage", value="usage") %>% 
    mutate(QuotavUsage = gsub("hard", "quota", QuotavUsage),
           usage = usage / 1000^unit_exp)
  
  # Plot the data as a time series
  ggplot(data = plt_data) + 
    geom_line(mapping = aes(x = day, y = usage, color = QuotavUsage)) +
    labs(x = "Date", y = input$units, color = "") +
    ggtitle(paste(plt_title, "Storage Usage Over Time", sep = " - "))
})