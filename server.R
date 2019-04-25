#########################
# R/CFB DATA PROCESSING #
#########################

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


# Load and clean data
cfb = fread("Full_Scraped_Comment_List.csv")

# Process flairs
unique_flairs1 = unique(cfb$Comment_Flair_1)
unique_flairs2 = unique(cfb$Comment_Flair_2)
unique_flairs = unique(c(unique_flairs1, unique_flairs2))
unique_flairs = unique(gsub('[[:digit:]]+', '', unique_flairs))

# Team names
unique_teams = data.table(School_Name = unique(cfb$School_Name))
unique_teams[, Flair_Conversion := tolower(gsub(" ", "", School_Name))]
unique_teams[, Flair_Match := Flair_Conversion %in% unique_flairs]

# Fix incorrect flair names
unique_teams[School_Name == "East Carolina", Flair_Conversion := "ecu"]
unique_teams[School_Name == "Florida Atlantic", Flair_Conversion := "fau"]
unique_teams[School_Name == "Louisiana-Lafayette", Flair_Conversion := "louisiana"]
unique_teams[School_Name == "Louisiana Monroe", Flair_Conversion := "ulm"]
unique_teams[School_Name == "Hawai'i", Flair_Conversion := "hawaii"]
unique_teams[School_Name == "Miami (OH)", Flair_Conversion := "miamioh"]
unique_teams[School_Name == "Texas A&M", Flair_Conversion := "texasam"]
unique_teams[School_Name == "Western Kentucky", Flair_Conversion := "wku"]

# Merging the school name of the flair back into the database
cfb = merge(cfb, unique_teams[, .(Flair_1_School=School_Name, Flair_Conversion)],
            by.x="Comment_Flair_1", by.y="Flair_Conversion", all.x=T)
cfb = merge(cfb, unique_teams[, .(Flair_2_School=School_Name, Flair_Conversion)],
            by.x="Comment_Flair_2", by.y="Flair_Conversion", all.x=T)

# Remove any rows where both schools are NA
cfb = cfb[!(is.na(Flair_1_School) & is.na(Flair_2_School))]

# If only flair 1 is present, flair 1 gets 100%. If Flair 2 is present, 2/3 - 1/3 split
cfb[, `:=`(Flair_1_Points = ifelse(is.na(Flair_2_School), 1, .666),
           Flair_2_Points = ifelse(is.na(Flair_2_School), 0, .334))]

# Calculate totals for each school combination
team_grid = as.data.table(expand.grid(Giving_Team = unique_teams$School_Name,
                                      Receiving_Team = unique_teams$School_Name))
team_grid[, Same.School := Giving_Team == Receiving_Team]
flair_1_table = cfb[, .(Flair_1_Points = sum(Flair_1_Points, na.rm=T)),
                    by=.(Flair_1_School, School_Name)]
flair_2_table = cfb[, .(Flair_2_Points = sum(Flair_2_Points, na.rm=T)),
                    by=.(Flair_2_School, School_Name)]
team_grid = merge(team_grid, flair_1_table,
                  by.x=c("Giving_Team", "Receiving_Team"),
                  by.y=c("Flair_1_School", "School_Name"), all.x=T)
team_grid = merge(team_grid, flair_2_table,
                  by.x=c("Giving_Team", "Receiving_Team"),
                  by.y=c("Flair_2_School", "School_Name"), all.x=T)

# Total points given
team_grid[, Total_Points_Given := rowSums(team_grid[, .(Flair_1_Points, Flair_2_Points)], na.rm=T)]

# Calculate the total points given and received by each team
giving_teams = team_grid[, .(Points_Given_by_Giver = sum(Total_Points_Given, na.rm=T)),
                         by=.(Giving_Team)]
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
               width="100%") %>%
      visOptions(highlightNearest = TRUE)
  })
}
