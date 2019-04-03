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
      # Project storage by user
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
      # User can change units for plots where that is useful
      conditionalPanel( condition = "input.which_table == 'project' ||
                        input.which_table == 'project_users' ||
                        input.which_table == 'scratch'",
                        selectInput(inputId = "units", label = "Usage Units", 
                                    choices = unit_choices, selected = "Megabytes (MB)")),
      # Download button
      downloadButton(outputId = "download", label = "Download")
      
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  # Pick the log type
  observe({
    switch(input$which_table,
           # Project logs
           project = source("app_project.R", local = T),
           # Project logs by user
           project_users = source("app_project_users.R", local = T),
           # Scratch logs
           scratch = source("app_scratch.R", local = T)
    )
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