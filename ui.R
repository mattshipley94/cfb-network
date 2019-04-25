##################
# R/CFB UI SETUP #
##################

# Loading required libraries
library(visNetwork)

# Running UI
fluidPage(
  titlePanel("CFB Network Explorer"),
  visNetworkOutput("network")
)