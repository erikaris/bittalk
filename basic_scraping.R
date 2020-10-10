install.packages('tidyverse')
install.packages('rvest')

library(tidyverse)
library(rvest)

countries = 'https://apps.who.int/bloodproducts/snakeantivenoms/database/SearchFrm.aspx' %>%
  read_html() %>%
  html_node('body #ddlCountry') %>% 
  html_nodes('option')                         # Parse dropdown select-option country

countryIds = countries %>% html_attrs()        # Get id from attribute
countryNames = countries %>% html_text()       # Get name from text

allSnakes <- NULL

for(countryIdx in seq(1, length(countryIds))) {
  tryCatch({
    countryId = countryIds[[countryIdx]][['value']]
    countryName = countryNames[[countryIdx]]
    
    snakes = paste0('https://apps.who.int/bloodproducts/snakeantivenoms/database/SnakeAntivenomListFrm.aspx?@CountryID=', countryId) %>% 
      read_html() %>%                           # Fetch html source
      html_node('body #SnakesGridView') %>%     # Find element by #SnakesGridView --> it's a table
      html_table(fill = TRUE)                   # Convert to dataframe
    
    snakes = cbind(snakes, 'Country name'= countryName)      # Add country name column
    nRows = ifelse(length(snakes) > 10, 10, length(snakes))  # Data available in row 1st - 10th
    snakes = snakes[1:nRows,]                                
    snakes = snakes[!is.na(snakes[['Cat**']]), ]             # Remove rows where cat** column is NA
    
    if (is.null(allSnakes)) allSnakes <- snakes              # 1st iteration 
    else allSnakes <- rbind(allSnakes, snakes)               # Next iteration
  }, error = function(e){})
}

allSnakes