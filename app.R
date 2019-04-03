library("shiny")
library("tidyverse")
library("RSQLite")

# Update database with new logs since last run
source("read_logs.R")

# Connect to database
db = dbConnect(SQLite(), dbname="logs.db")

# Unit selections
unit_choices <- c("Kilobytes (kB)", "Megabytes (MB)", "Gigabytes (GB)",
                  "Terabytes (TB)", "Petabytes (PB)", "Exabytes (EB)")

# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Application title
  titlePanel("Log Data"),
  
  # Sidebar with a slider with input
  sidebarLayout(
    sidebarPanel(
      # Date range to track usage
      dateRangeInput(inputId = "dates", label = "Date Range"),
      # Select box for looking at either projects or users
      selectInput(inputId = "which_table", label = "Log", 
                  choices = log_types),
      # Project storage
      conditionalPanel( condition = "input.which_table == 'project'",
                        radioButtons(inputId = "selectProject",
                                     label = "Project",
                                     choices = unique(unlist(dbGetQuery(db, 
                                                                        "SELECT project FROM project"), use.names = F)))),
      conditionalPanel( condition = "input.which_table == 'project_users'",
                        radioButtons(inputId = "selectUsers",
                                     label = "Users",
                                     choices = unique(unlist(dbGetQuery(db, 
                                                                        "SELECT user FROM project_users"), use.names = F))))
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      # Plot
      plotOutput("quotas"),
      # Select Units
      selectInput(inputId = "units", label = "Usage Units", 
                  choices = unit_choices, selected = "Megabytes (MB)"),
      # Download button
      downloadButton(outputId = "download", label = "Download")
      
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  # Pick the appropriate date range
  observe({
    switch(input$which_table,
           project = source("app_project.R", local = T),
           project_users = source("app_project_users.R", local = T),
           scratch = source("app_scratch.R", local = T)
    )
  })
  
  # Render plots 
  output$quotas <- renderPlot({
    # Get dates
    start_date <- input$dates[1]
    end_date <- input$dates[2]
    
    # Projects data
    if(input$which_table == "project"){
      plt_data <- as_tibble(dbGetQuery(db, "SELECT project, used, hard, day FROM project")) %>% 
        mutate(day = as.Date(day, format="%Y-%m-%d")) %>% 
        filter(project %in% input$selectProject) %>% 
        filter(day >= start_date & day <= end_date)
      plt_title <- input$selectProject
    }
    
    # Project data by user
    if(input$which_table == "project_users"){
      plt_data <- as_tibble(dbGetQuery(db, "SELECT user AS project, used, hard, day FROM project_users")) %>% 
        mutate(day = as.Date(day, format="%Y-%m-%d")) %>% 
        filter(project %in% input$selectUsers) %>% 
        filter(day >= start_date & day <= end_date)
      plt_title <- input$selectUsers
    }
    
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
  
  # Functionality to save a picture of the graph
  output$download <- downloadHandler(filename = "log_graph.png",
                                     content = function(file){
                                       ggsave(file, device = "png")
                                     },
                                     contentType = "image/png"
  )
}

# Run the application 
shinyApp(ui = ui, server = server)