# User Interface for R Shiny App
fluidPage(
  titlePanel("CFB Network Explorer"),
  visNetworkOutput("network")
)