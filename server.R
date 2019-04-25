######################
# R/CFB SERVER SETUP #
######################

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

# Read team_grid file
team_grid = fread("cfb_network_team_grid.csv")

# Calculate the total points given and received by each team
giving_teams = team_grid[, .(Points_Given_by_Giver = sum(Total_Points_Given, na.rm=T)),
                         by=Giving_Team]
receiving_teams = team_grid[, .(Points_Rec_by_Receiver = sum(Total_Points_Given, na.rm=T)),
                            by=.(Receiving_Team)]

# Merge back in with the cfb dataset
team_grid = merge(team_grid, receiving_teams, by="Receiving_Team", all.x=T)
team_grid = merge(team_grid, giving_teams, by="Giving_Team", all.x=T)

# Calculate unidirectional affinity
team_grid[, `:=`(Percentage_of_Givers_Points = Total_Points_Given / Points_Given_by_Giver,
                 Percentage_of_Receivers_Points = Total_Points_Given / Points_Rec_by_Receiver,
                 Unidirectional_Affinity = Total_Points_Given / (sqrt(Points_Given_by_Giver * Points_Rec_by_Receiver)))]

# Merge in the unidirectional affinity in the opposite direction. Calculate affinity score
team_grid = merge(team_grid, team_grid[, .(Giving_Team, Receiving_Team, Reverse_Affinity = Unidirectional_Affinity)],
                  by.x=c("Giving_Team", "Receiving_Team"), by.y=c("Receiving_Team", "Giving_Team"), all.x=T)
team_grid[, Affinity_Score := sqrt(Unidirectional_Affinity * Reverse_Affinity)]

# Remove teams' comments to themselves
team_grid = team_grid[Giving_Team != Receiving_Team]

# Create visualization
nodes = data.table("label" = giving_teams[, Giving_Team],
                   "id" = giving_teams[, Giving_Team],
                   "value" = giving_teams[, Points_Given_by_Giver])
edges = data.table("from" = team_grid$Giving_Team,
                   "to" = team_grid$Receiving_Team,
                   "value" = team_grid$Affinity_Score)

# Getting rid of duplicate rows
edges[, `:=`(First_Team = ifelse(from < to, from, to),
             Second_Team = ifelse(from > to, from, to))]
edges[, Unique_Key := paste0(First_Team, "_", Second_Team)]
edges = edges[!duplicated(Unique_Key)]

top_40_teams = giving_teams[order(-Points_Given_by_Giver)][1:40, Giving_Team]
# nodes = nodes[id %in% top_40_teams]
# edges = edges[from %in% top_40_teams & to %in% top_40_teams]
edges = edges[order(-value)][1:250]
nodes = nodes[label %in% edges$from | label %in% edges$to]


# Set up RShiny site
function(input, output) {
  
  output$network <- renderVisNetwork({
    
    nodes <- nodes
    edges <- edges
    
    visNetwork(nodes, edges,
               height="1000px",
               width="1000px") %>%
      visOptions(highlightNearest = TRUE)
  })
}
