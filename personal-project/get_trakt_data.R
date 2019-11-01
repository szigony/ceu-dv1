### Libraries
#remotes::install_github('jemus42/tRakt')
library(tRakt)
library(tidyverse)

### Set working directory
setwd('C:/Users/szige/Desktop/CEU/2019-2020 Fall/Data Visualization 1/personal-project')

### trakt datasets (http://jemus42.github.io/tRakt/index.html)
# Get view history from trakt
my_history <- user_history(user = "szigony", type = c("shows"), limit = 11000) %>% 
  select(watched_at, title, episode_season, episode_episode, trakt_id = trakt, imdb_id = imdb)

# Add 'watched_episodes'
my_history <- my_history %>% 
  inner_join(my_history %>% 
                group_by(trakt_id) %>% 
                summarise(watched_episodes = n())) %>% 
  select(-c(episode_season, episode_episode, watched_at))

# Additional information about shows
summary <- shows_summary(unique(my_history$trakt_id), extended = "full") %>% 
  select(trakt_id = trakt, runtime, certification, network, country, language, genres, aired_episodes)

### IMDB rating dataset (https://www.imdb.com/interfaces/)
# Downloaded on 2019/11/01
ratings <- readr::read_tsv('title_ratings.tsv') %>% 
  filter(tconst %in% unique(my_history$imdb_id)) %>% 
  select(imdb_id = tconst, rating = averageRating, votes = numVotes) %>% 
  distinct()

# Combined dataset for R
data <- my_history %>% 
  inner_join(summary) %>% 
  inner_join(ratings) 
