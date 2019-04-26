##################
# R/CFB UI SETUP #
##################

# Loading packages
library(data.table)
library(igraph) 
library(network) 
library(sna)
library(visNetwork)
library(threejs)
library(networkD3)
# library(ndtv)
library(shiny)
library(shinydashboard)

# Running UI
dashboardPage(
  dashboardHeader(title = "CFB Fan Network",
                  dropdownMenu(type = "messages",
                               messageItem(
                                 from = "Your Mom",
                                 message = "Love you!",
                                 time = "2019-04-25"
                               ),
                               messageItem(
                                 from = "Your Boss",
                                 message = "Keep up the good work!",
                                 time = "2019-04-24"
                               ),
                               messageItem(
                                 from = "IT Help Desk",
                                 message = "Your dashboard is now set up.",
                                 time = "2019-04-23",
                                 icon = icon("life-ring")
                               )
                  )),
  dashboardSidebar(
    sidebarMenu(
      menuItem("CFB Network", tabName = "network", icon = icon("dashboard")),
      menuItem("File Upload", tabName = "fileupload", icon = icon("file"))
    )
  ),
  
  dashboardBody(
    tabItems(
      # First tab
      tabItem(tabName = "network",
              visNetworkOutput("network",
                               height = "89vh")),
      
      # Second tab
      tabItem(tabName = "fileupload",
              # Input: Select a file ----
              fileInput("file1", "Choose CSV File",
                        multiple = FALSE,
                        accept = c("text/csv",
                                   "text/comma-separated-values,text/plain",
                                   ".csv")),
              
              # Horizontal line ----
              tags$hr(),
              
              # Input: Checkbox if file has header ----
              checkboxInput("header", "Header", TRUE),
              
              # Input: Select separator ----
              radioButtons("sep", "Separator",
                           choices = c(Comma = ",",
                                       Semicolon = ";",
                                       Tab = "\t"),
                           selected = ","),
              
              # Input: Select quotes ----
              radioButtons("quote", "Quote",
                           choices = c(None = "",
                                       "Double Quote" = '"',
                                       "Single Quote" = "'"),
                           selected = '"'),
              
              # Horizontal line ----
              tags$hr(),
              
              # Input: Select number of rows to display ----
              radioButtons("disp", "Display",
                           choices = c(Head = "head",
                                       All = "all"),
                           selected = "head"),
              
              # Download button
              downloadButton("downloadData", "Download"),
              
              # Output: Data file ---
              tableOutput("contents")
              )
    )
      
  )
  
)
