library("shiny")
library("tidyverse")
library("RSQLite")

# Connect to database
db = dbConnect(SQLite(), dbname="logs.db")

# Unit selections
unit_choices <- c("Kilobytes (kB)", "Megabytes (MB)", "Gigabytes (GB)",
                  "Terabytes (TB)", "Petabytes (PB)", "Exabytes (EB)")

# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Application title
  titlePanel("Storage Quotas"),
  
  # Sidebar with a slider with input
  sidebarLayout(
    sidebarPanel(
      # Date range to track usage
      dateRangeInput(inputId = "dates", label = "Date Range", start = "2019-02-14",
                     end = as_tibble(dbGetQuery(db, "SELECT MAX(day) FROM project_quotas"))$`MAX(day)`),
      # Select box for looking at either projects or users
      selectInput(inputId = "which_table", label = "Projects or Users?", 
                  choices = c("Projects", "Users")),
      # Check boxes for picking users/projects
      conditionalPanel( condition = "input.which_table == 'Projects'",
                        radioButtons(inputId = "selectProject",
                                     label = "Project",
                                     choices = unique(unlist(dbGetQuery(db, 
                                                                        "SELECT project FROM project_quotas"), use.names = F)))),
      conditionalPanel( condition = "input.which_table == 'Users'",
                        radioButtons(inputId = "selectUsers",
                                     label = "Users",
                                     choices = unique(unlist(dbGetQuery(db, 
                                                                        "SELECT user FROM user_quotas"), use.names = F))))
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
  
  # Render plots 
  output$quotas <- renderPlot({
    # Get dates
    start_date <- input$dates[1]
    end_date <- input$dates[2]
    
    # Projects data
    if(input$which_table == "Projects"){
      plt_data <- as_tibble(dbGetQuery(db, "SELECT project, used, hard, day FROM project_quotas")) %>% 
        mutate(day = as.Date(day, format="%Y-%m-%d")) %>% 
        filter(project %in% input$selectProject) %>% 
        filter(day >= start_date & day <= end_date)
      plt_title <- input$selectProject
    }
    
    # User data
    if(input$which_table == "Users"){
      plt_data <- as_tibble(dbGetQuery(db, "SELECT user AS project, used, hard, day FROM user_quotas")) %>% 
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
  output$download <- downloadHandler(filename = "project_quota.png",
                                     content = function(file){
                                       ggsave(file, device = "png")
                                     },
                                     contentType = "image/png"
  )
}

# Run the application 
shinyApp(ui = ui, server = server)