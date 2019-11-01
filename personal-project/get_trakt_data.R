#remotes::install_github("jemus42/tRakt")
library(tRakt)
library(tidyverse)

my_history <- user_history(user = "szigony", type = c("shows"), limit = 11000) %>% 
  select(watched_at, title, episode_season, episode_episode, trakt_id = trakt)
