# log_stats

## Introduction
`log_stats` is an RShiny dashboard that is used to track statistics for users. It creates plots of user's usage data; it allows you to change the date range, units, and log type; and you can download picture files of the plot output. There are two parts: the RShiny app and the backend scripts that update the database. These parts are coupled, but can be decoupled with minimal modification. The backend searches available log files and puts them into a SQLite database. The front end serves the RShiny app in a web browser.

## Setup

There are two ways to run the app. You can host everything on the cluster. Place the `log_stats/` directory in the appropriate place and create the following directory: `log_stats/logs/`. You can also run the app locally, placing back-end files in the appropriate place on the cluster. **Regardless of which setup you choose, the back-end scripts must be on the cluster. They will look for the log files in `log_stats/logs/`**.

### Running the App on the Cluster

The code is currently ready for this setup. When `app.R` runs, it will first call `read_logs.R` to initiate the back end before serving up the GUI. The back end will then look for `logs/` and create a SQLite database if one does not exist already. See this page for information on hosting RShiny servers: https://www.rstudio.com/products/shiny/shiny-server/.

### Running the App Locally

You can run the front end locally. This only requires placing the back-end scripts on the cluster and a standard R installation. Place log files in `log_stats/logs/` and run `read_logs.R`. If `logs.db` does not exist, it will create a new database; otherwise, it updates the current database. Copy the updated SQLite file to your local machine.

Before running the app locally, comment out line 6: `source("read_logs.R")`. This runs the back-end scripts and updates the database before serving the GUI. Without this line, the app will simply use the `logs.db` file you placed in its directory. 

## Using the App

- From within RStudio: Click on `app.R`. Click the green play button at the top of the window.

- From the command line: `R -e "shiny::runApp('logstats/')"`.

The app will launch in a new browser tab.

## Files
- `.gitignore` - The `.gitignore` file.
- `README.md` - The README file.
- `log_stats.Rproj` -  RStudio metadata for the project. When opening the project from within RStudio, use this file to reopen the project.

### Front End

- `app.R` - Main shiny app.
  - Library dependencies: `shiny`, `tidyverse`, and `RSQLite`.
  - File dependencies: `app_project.R`, `app_project_users.R`, `app_scratch.R`, and `read_logs.R` (optional—see *Running the App Locally* above).
- `app_project.R` - App interface items for Project Storage statistics.
- `app_project_users.R` - App interface items for Project Storage statistics by individual Cluster user.
- `app_scratch.R` - App interface items for Scratch user statistics.

### Back End

- `read_logs.R` - The primary back-end script. It reads all the logs in the `logs/` folder and checks to see that entries are already in `logs.db`. If it discovers a new entry, it adds it to the database.
  - Library dependencies: `tidyverse` and `RSQLite`.
  - File dependencies: `functions.R`.

- `functions.R` - Assorted functions. Other scripts call these functions.
  - Library dependencies: `tidyverse`, and `RSQLite`.
  - File dependencies: `log_readers.R`.
- `log_readers.R` - Functions for parsing content from log files and creating a Tibble out of the data. These functions could be put in `functions.R`, but I chose to give them their own file since they all fall into a specific category.
  - Library dependencies: `tidyverse`.
