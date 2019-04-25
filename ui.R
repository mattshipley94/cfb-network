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
library(ndtv)
library(shiny)

# Running UI
fluidPage(
  titlePanel("CFB Network Explorer"),
  visNetworkOutput("network")
)