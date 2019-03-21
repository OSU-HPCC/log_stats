library("tidyverse")
library("RSQLite")

# Get the list of log files for each type of log
filenames <- list(scratch_logs = "[[:digit:]]*scratchuse", 
                  project_logs = "[[:digit:]]*project[[:digit:]]*quotalog.txt")
