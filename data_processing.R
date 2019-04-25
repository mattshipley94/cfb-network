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

# Write team_grid to .csv
write.csv(team_grid, "cfb_network_team_grid.csv", row.names=F)
