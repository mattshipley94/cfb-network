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
      menuItem("Widgets", tabName = "widgets", icon = icon("th"))
    )
  ),
  
  dashboardBody(
    tabItems(
      # First tab
      tabItem(tabName = "network",
              visNetworkOutput("network",
                               height = "89vh")),
      
      # Second tab
      tabItem(tabName = "widgets")
    )
      
  )
  
)
