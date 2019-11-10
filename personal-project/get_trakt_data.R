### Libraries
#remotes::install_github('jemus42/tRakt')
library(tRakt)
library(tidyverse)
library(lubridate)

### Set working directory
setwd('C:/Users/szige/Desktop/CEU/2019-2020 Fall/Data Visualization 1/personal-project')

### trakt datasets (http://jemus42.github.io/tRakt/index.html)
# Get view history from trakt
my_history <- user_history(user = "szigony", type = c("shows"), limit = 20000) %>% 
  select(watched_at, episode_season, episode_episode, trakt_id = trakt, imdb_id = imdb)

# Separate view history
view_history <- my_history %>% 
  select(c(trakt_id, season = episode_season, episode = episode_episode, watched_at))

# Add 'watched_episodes'
my_history <- my_history %>% 
  select(-c(episode_season, episode_episode, watched_at)) %>% 
  distinct()

# Additional information about shows
show_summary <- shows_summary(unique(my_history$trakt_id), extended = "full") %>% 
  select(trakt_id = trakt, title, runtime, certification, network, country, language, genres, aired_episodes) %>% 
  drop_na(genres) %>% 
  unnest(genres) %>% 
  inner_join(
    my_history %>% 
      group_by(trakt_id) %>% 
      summarise(watched_episodes = n()),
    by = 'trakt_id'
  )

# Combine datasets from 'trakt' and add 'is_axed' variable
summary <- my_history %>% 
  inner_join(view_history, by = 'trakt_id') %>% 
  inner_join(show_summary, by = 'trakt_id')

axed_shows <- view_history %>%
  inner_join(show_summary, by = 'trakt_id') %>% 
  select(trakt_id, watched_episodes, aired_episodes, watched_at) %>% 
  filter(watched_episodes < aired_episodes) %>% 
  group_by(trakt_id) %>% 
  summarise(last_watched = max(watched_at)) %>% 
  ungroup() %>% 
  mutate(is_axed = case_when(
    last_watched < today() - years(2) ~ TRUE,
    TRUE ~ FALSE
  )) %>% 
  select(trakt_id, is_axed)

summary <- show_summary %>% 
  inner_join(axed_shows, by = 'trakt_id') %>% 
  inner_join(view_history, by = 'trakt_id') %>% 
  inner_join(my_history, by = 'trakt_id')

### IMDB rating dataset (https://www.imdb.com/interfaces/)
# Downloaded on 2019/11/01
ratings <- readr::read_tsv('title_ratings.tsv') %>% 
  filter(tconst %in% unique(my_history$imdb_id)) %>% 
  select(imdb_id = tconst, rating = averageRating, votes = numVotes) %>% 
  distinct()

# Combine datasets
data <- summary %>% 
  inner_join(ratings, by = 'imdb_id')

# Save to csv
write.csv(data, 'szigony_watch_history.csv', row.names = FALSE)
