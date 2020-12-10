
################################################################################################
#
# This programme is built on top of "testing_rtweet.R" by Jingxi Chen on Sep 30th, 2017
#
# It will first search for tweets mentioning "climate change". 
# And then record interesting sumamry figures into pdf file.
# 
# After that it will keep track of occurences for popular hashtags in these tweets. 
# The programme will automatically add new hot tags to be tracked 
# and stop following tags that are no longer popular. 
# Ultimately, a trend (time series) for each hashtag can be plotted.
#
# Last, it will collect some sample tweet content and record it in another table (rds file)
#
# Beware: Tweets sent by robots may biased our selection for pop hashtags. But also note that most 
# bots are just broadcasting current hot news and are harmless to our results.
#
# Monitor the 7th plot for "What app are people tweeting from" which will reveal proportion of robots. 
# Other viz may help too.
# Also can check sample tweets recorded daily in rds file.
# https://botometer.iuni.iu.edu/#!/ This website might as well assist in identifying bots
#
# This programme is recommended to run daily at same time
#
################################################################################################
##> because of error in pandoc. First check: Sys.getenv("RSTUDIO_PANDOC") the change the path below
##> then we have to re-set the locale to "en_US.UTF-8" instead of "C"
Sys.setenv(RSTUDIO_PANDOC="/Applications/RStudio.app/Contents/MacOS/pandoc")
Sys.setlocale(category = "LC_ALL", locale = "en_US.UTF-8")

con <- file(paste0(format(Sys.time(), '%Y%m%d_%H'),"_runningauto.log"))
sink(con, append=TRUE)  # Log the output message into a text file for reference or debugging
sink(con, append=TRUE, type="message")

library(tidyverse)
library(rtweet)
cat("Finish loading packages!\n")

# # setting up twitter app with API Key:
# appname <- "rtweet_testing_17"
# key <- "GVhC901mN83nubMrP8CXbfWMq"
# secret <- "WfqjVrjmh80Du4JTHhv36k0kHVO3Hvagky7d94NE0irgfeeCy3"
# ## create token named "twitter_token"
# twitter_token <- create_token(app = appname, consumer_key = key, consumer_secret = secret)

# NOTE: the first time this is run it req package httpuv to be installed (not loaded?)
# a browser will open as ask you to authenticate the app.

# For the rtweet package documentation, see here:
# https://mkearney.github.io/rtweet/reference/index.html

# for twitter API documentation, see here:
# https://dev.twitter.com/rest/reference/get/search/tweets
raw_large <- 
  search_tweets(q='"climate change" OR "global warming"',
                n=18000, 
                # parse = FALSE,
                include_rts = TRUE,
                geocode = lookup_coords("usa"),
                #geocode = "39.8,-95.583068847656,2500km",  # !!! Limit to USA tweets (this includes 48 states)
                lang = "en",
                retryonratelimit = TRUE#,
                #token=twitter_token
                )
#t_large <- parse_data(raw_large) %>% as_tibble
t_large <- as_tibble(raw_large)
saveRDS(t_large, file=paste0(format(Sys.time(), '%Y%m%d_%H'), "_dailytweets.rds"))


#######################################################
#
#  Recording daily summary figures (8 figures per day)
#
#######################################################

# Figures will be generated in daily reports using 
# R mark down in "AutoReport_Climatechange.rmd"
# No need to create separate pdf file for figures now
if (FALSE){
# ggplot2 theme -----------------------------------------------------------
  my.ggtheme <- 
    theme_bw(12) + 
    theme(line = element_line(size=1, lineend = "square", color = "black"),
          axis.line = element_line(size=1, lineend = "square", color = "black"),
          axis.ticks = element_line(color = "black"),
          axis.text = element_text(color = "black"),
          panel.grid = element_line(size=0.3, color = "grey92"),
          panel.border = element_blank(),
          strip.background = element_blank(),
          panel.background = element_blank(),
          plot.background = element_blank(),
          plot.title = element_text(hjust=0.5,size = rel(1.2)))

  # Miscellaneous summary
# pdf(paste0(format(Sys.time(), '%Y%m%d_%H'),"_Figures.pdf")) # Record figures in pdf

png(paste0(format(Sys.time(), '%Y%m%d_%H'),"_Figures.png"))

t_large %>%
  mutate(`One or more retweets` = retweet_count > 0,
         `Favorited one or more times` = favorite_count > 0,
         #`Is the text the full 140 charachters` = str_length(text) >= 140, # !!! some have more than 140
         `Is the text the full 280 charachters` = str_length(text) >= 280, # !!! new limit
         #`Is quote status (??)` = is_quote_status,
         `Is quote status (??)` = is_quote,
         `Is a retweet` = is_retweet,
         #`In reply to a status (??)` = !is.na(in_reply_to_status_status_id),
         `In reply to a status (??)` = !is.na(reply_to_status_id),
         `Has a media url (gif etc?)` = !is.na(media_url),
         #`Has a regular url` = !is.na(urls_display),
         `Has a regular url` = !is.na(urls_url),
         `Has one or more user mentions` = !is.na(mentions_screen_name),
         `Has one or more hashtags` = !is.na(hashtags),
         #`Has geoloc` = !is.na(place_id)) %>%
         `Has geoloc` = !is.na(place_url)) %>%
  summarize_at(vars(contains(" ")), funs( mean(.) )) %>% # !!! can simplify sum(,)/n() to mean(.)
  gather(variable.name,percent,everything()) %>%
  ggplot(aes(x=variable.name,y=percent)) +
  geom_bar(stat="identity",color="black",fill="grey70") + 
  coord_flip() +
  scale_y_continuous(limits=c(0,1), labels = scales::percent) + 
  labs(title = "Search term: 'climate change'\nCharacteristics Summary", # Make figure title clearer
       x="", y="Percentage of all tweets", caption = paste0(Sys.time(),"\n","Searched ", nrow(t_large)," tweets in total")) + 
  my.ggtheme + theme(panel.grid.major.y = element_blank())
}
# What are the most common hastags?
display.top.n <- 25
# commontags <- t_large %>%
#   filter(!is.na(hashtags)) %>%
#   {str_split(.$hashtags," ")} %>%
#   {tibble(hashtags = unlist(.))} %>%  
#   filter(! grepl("climatechange|^climate$|^change$|globalwarming|^global$|^warming$",
#                  hashtags, ignore.case = TRUE) ) %>% # Trivial. No need to show
#   sapply(., tolower) %>% as.tibble %>%    # Standardize all hashtags to lower case Starting from Oct 27th
#   count(hashtags) %>%
#   mutate(hashtags = str_c("#",hashtags)) %>%
#   arrange(desc(n))

commontags <- t_large %>%
  filter(!is.na(hashtags)) %>%
  #{str_split(.$hashtags," ")} %>%
  {str_split(unlist(.$hashtags)," ")} %>%
  {tibble(hashtags = unlist(.))} %>%  
  filter(! grepl("climatechange|^climate$|^change$|globalwarming|^global$|^warming$",
                 hashtags, ignore.case = TRUE) ) %>% # Trivial. No need to show
  sapply(., tolower) %>% as_tibble %>%    # Standardize all hashtags to lower case Starting from Oct 27th
  count(hashtags) %>%
  mutate(hashtags = str_c("#",hashtags)) %>%
  arrange(desc(n))

#saveRDS(commontags, file="commontags.rds")

if (FALSE){
commontags %>%
  slice(1:display.top.n) %>%
  ggplot(aes(x=reorder(hashtags,n),y=n)) +
  geom_bar(stat="identity",color="black",fill="grey70") + 
  coord_flip() +
  labs(title = "Search term: 'climate change'\nMost common hastags",
       x="Top hastags by # of occurances", y="Number of occurances", caption = paste0(Sys.time(),"\n","Searched ", nrow(t_large)," tweets in total")) + 
  my.ggtheme + theme(panel.grid.major.y = element_blank())

# how many times is each user tweeting?
t_large %>%
  group_by(user_id) %>%
  summarize(ntweets = n()) %>%
  ggplot(aes(x=ntweets)) +
  geom_bar(stat="count",color="black",fill="grey70") + 
  scale_y_continuous(trans="log10",breaks=c(1,10,100,1000)) + 
  labs(title = "Search term: 'climate change'\nHow many times is each user tweeting?",# Make figure title clearer
       x="Number of tweets per user",y="Number of users (log10)") + 
  my.ggtheme

# Top users by # of tweets
display.top.n <- 25
t_large %>%
  group_by(user_id,screen_name) %>%
  summarize(ntweets = n()) %>% ungroup() %>%
  mutate(screen_name = str_c("@",screen_name)) %>%
  arrange(desc(ntweets)) %>% slice(1:display.top.n) %>%
  ggplot(aes(x=reorder(screen_name,ntweets),y=ntweets)) +
  geom_bar(stat="identity",color="black",fill="grey70") + 
  coord_flip() +
  labs(title = "Search term: 'climate change\nTop users by # of tweets'", # Make figure title clearer
       x="Top users", y="Number of tweets") + 
  my.ggtheme + 
  theme(panel.grid.major.y = element_blank())

# how often is each tweet retweeted? (using the actual RT button; 
# manual RTs don't get counted I think)
tmp.log.width <- 1/3
t_large %>%
  mutate(retweet_count_recode.zero.for.log.scale = if_else(retweet_count==0,10^-(2*tmp.log.width),as.double(retweet_count))) %>%
  ggplot(aes(x=retweet_count_recode.zero.for.log.scale)) +
  geom_histogram(boundary = tmp.log.width + (tmp.log.width/2),
                 binwidth = tmp.log.width,
                 color="black",fill="grey70") + 
  scale_x_continuous(trans="log10", breaks=c(10^-(2*tmp.log.width),1,10,100,1000,10000),labels=c(0,1,10,100,1000,10000)) + 
  labs(title = "Search term: 'climate change'\nHow often is each tweet retweeted?",
       x="Number of retweets",y="Count") + 
  my.ggtheme

# how often is a tweet favorited?
tmp.log.width <- 1/4
t_large %>%
  mutate(favorite_count_recode.zero.for.log.scale = if_else(favorite_count==0,10^-(2*tmp.log.width),as.double(favorite_count))) %>%
  ggplot(aes(x=favorite_count_recode.zero.for.log.scale)) +
  geom_histogram(boundary = tmp.log.width + (tmp.log.width/2),
                 binwidth = tmp.log.width,
                 color="black",fill="grey70") + 
  scale_x_continuous(trans="log10", breaks=c(10^-(2*tmp.log.width),1,10,100,1000,10000),labels=c(0,1,10,100,1000,10000)) + 
  labs(title = "Search term: 'climate change'\nHow often is a tweet favorited?",
       x="Number of times favorited",y="Count") + 
  my.ggtheme

# What app are people tweeting from?
# ... this may seem dumb, but check this out! http://varianceexplained.org/r/trump-tweets/
display.top.n <- 25
t_large %>%
  count(source) %>%
  arrange(desc(n)) %>%
  slice(1:display.top.n) %>%
  ggplot(aes(x=reorder(source,n),y=n)) +
  geom_bar(stat="identity",color="black",fill="grey70") + 
  coord_flip() +
  labs(title = "Search term: 'climate change'\nWhat app are people tweeting from?",
       x="Top twitter clients by # of tweets", y="Number of tweets") + 
  my.ggtheme + theme(panel.grid.major.y = element_blank())


# quick maps from the geoloc data  (only ~2% tweets add geoloc)
# t_large %>%
#   filter(!is.na(bounding_box_coordinates)) %>%
#   separate(bounding_box_coordinates, into=c("lon1","lon2","lon3","lon4","lat1","lat2","lat3","lat4"), sep=" ") %>%
#   ggplot() +
#   geom_path(data = map_data("state"), aes(x = long, y = lat, group = group)) + 
#   coord_map(projection = "mercator") + 
#   geom_point(aes(x=(as.numeric(lon1)+as.numeric(lon2))/2,y=(as.numeric(lat1)+as.numeric(lat3))/2), # Show geo mean location!!
#              color="red", alpha=0.66, size=1) + 
#   lims(x=c(-125,-65), y=c(25,50)) + 
#   labs(title = "Search term: 'climate change'",x=NULL,y=NULL) + 
#   my.ggtheme

t_large %>%
  select(bbox_coords) %>%
  filter(!is.na(bbox_coords)) %>%
  # There's probably a better way of doing this (without the regex)
  separate(bbox_coords, into=c("empty","lon1","lon2","lon3","lon4","lat1","lat2","lat3","lat4"), sep="^c\\(|\\)|,") %>%
  ggplot() +
  geom_path(data = map_data("state"), aes(x = long, y = lat, group = group)) + 
  coord_map(projection = "mercator") + 
  geom_point(aes(x=(as.numeric(lon1)+as.numeric(lon2))/2,y=(as.numeric(lat1)+as.numeric(lat3))/2), # Show geo mean location!!
             color="red", alpha=0.66, size=1) + 
  lims(x=c(-125,-65), y=c(25,50)) + 
  labs(title = "Search term: 'climate change'",x=NULL,y=NULL) + 
  my.ggtheme

dev.off() # End of pdf recording
cat("Finished plotting!\n")
}

#######################################################
#
#  Recording popularity trend for hashtags
#
#######################################################

# When a hashtag enter the top n to be displayed list, add it into the track list
# Track it until it has fewer than 5 occurances

# # Initialize track list:
# tracklist <- matrix(commontags$n[1:display.top.n], nrow=1, ncol=display.top.n, dimnames = list(as.character(format(Sys.time(), '%Y%m%d_%H')), commontags$hashtags[1:display.top.n]))
# saveRDS(tracklist, file = "tracklist.rds")

# Update tracklist
tracklist <- readRDS("tracklist.rds")
cat("finish reading in tracklist\n")
# Begin daily update for hashtags occurances (growing # of rows for track list)
tracklist <- rbind(tracklist, NA)# Today's new row. First initialize using NA
rownames(tracklist)[nrow(tracklist)] <- as.character(format(Sys.time(), '%Y%m%d_%H'))
for (tag in colnames(tracklist)){
  if( tag %in% commontags$hashtags){ # Premise: the tag must occur in today's commontags list. Or just leave NA there

    if(!is.na(tracklist[nrow(tracklist)-1, tag])) { # Only update non-NA entry since NA entry means no longer following
      if(filter(commontags, hashtags==tag)$n >= 5) # Check to see if drop out of our track scope (fewer than 5) today
        tracklist[nrow(tracklist), tag] <- filter(commontags, hashtags==tag)$n # Update it
      # else just leave NA there
    }else if(filter(commontags, hashtags==tag)$n >= 5) # for those coming-back tags
      tracklist[nrow(tracklist), tag] <- filter(commontags, hashtags==tag)$n # Welcome back to our track list!
    # else just leave NA there
  }
}
cat("finish growing rows!\n")

# Begin daily check for any new hot hashtags (growing # of columns for track list)
# New trendy hashtags occur today that are not in our list:
newtrendy <- commontags$hashtags[1:display.top.n][! commontags$hashtags[1:display.top.n] %in% colnames(tracklist) ]
for (tag in newtrendy){ # Add them in track list (former counts will be NAs for these new comers)
  tracklist <- cbind(tracklist, c(rep(NA, nrow(tracklist)-1), filter(commontags, hashtags==tag)$n) )
}
if (length(newtrendy)>0){  # Don't forget to name the newly added column(s)
  colnames(tracklist)[ncol(tracklist)-(length(newtrendy)-1):0] <- newtrendy
}
cat("finish growing columns\n")
saveRDS(tracklist, file = "tracklist.rds")
cat("finish saving new tracklist\n")

#######################################################
#
#  Start to record daily tweets of interest
#
#######################################################

top.n.exp <- 5
# the top n favorited tweets:
top_favorite <- t_large %>%
  arrange(desc(favorite_count)) %>% select(text) %>% unique %>%
  slice(1:top.n.exp) 
# the top n retweeted tweets:
top_retweet <- t_large %>%
  arrange(desc(retweet_count)) %>%  select(text) %>% unique %>%  # !! Only keep unique top n tweets
  slice(1:top.n.exp)
  
# For daily top 5 popular hashtags, sample n examples (specified by top.n.exp variable)
# pop_hashtag <- 
#   as.data.frame(sapply(commontags$hashtags[1:5], function(tag) {
#     t_large %>%
#     {str_split(.$hashtags," ")} %>% grep(pattern = gsub("#","",tag), x=., ignore.case=TRUE) %>% slice(t_large, .) %>%
#       slice(sample(nrow(.), min(nrow(.), top.n.exp))) %>%  # Select n (n<total # of tweets) tweets examples randomly
#       select(text)
#   }), col.names = paste0("pop_hashtag", 1:5))


pop_hashtag <- 
  as.data.frame(sapply(commontags$hashtags[1:5], function(tag) {
    t_large %>%
      {str_split(unlist(.$hashtags)," ")} %>% 
      grep(pattern = gsub("#","",tag), x=., ignore.case=TRUE) %>% 
      slice(t_large, .) %>%
      slice(sample(nrow(.), min(nrow(.), top.n.exp))) %>%  # Select n (n<total # of tweets) tweets examples randomly
      select(text)
  }), col.names = paste0("pop_hashtag", 1:5))

# # Initialize daily samples
# daily_samples <- cbind(rep(format(Sys.time(), '%Y%m%d_%H'), top.n.exp), top_favorite, top_retweet, pop_hashtag)
# names(daily_samples)[1:3] <- c("Date", "top_favorite", "top_retweet")
# saveRDS(daily_samples, file = "daily_samples.rds")

# Update daily samples
# Combine these tweets together
daily_samples <- cbind(rep(format(Sys.time(), '%Y%m%d_%H'), top.n.exp), top_favorite, top_retweet, pop_hashtag)
names(daily_samples)[1:3] <- c("Date", "top_favorite", "top_retweet")
daily_samples = rbind(readRDS("daily_samples.rds"), daily_samples) # Update to the previous tweet list
# Just like the tracklist table, since new daily result is appended to the existing table, code need to be modified a bit if
# you are initializing the daily_samples table. This can simply be done by commenting (not running) the line of code above
saveRDS(daily_samples, file = "daily_samples.rds")
cat("finish saving new daily samples\n")

# And daily report will show sample tweets every day
# The following command will create daily html report using R mark down
#rmarkdown::render("AutoReport_Climatechange.rmd", output_file = paste0(format(Sys.time(), '%Y%m%d_%H'),"_CC_report.html"))
rmarkdown::render("AutoReport_Climatechange_2.0.rmd",
                  output_format = "html_document",
                  output_file = paste0(format(Sys.time(), '%Y%m%d_%H'),"_CC_report.html"),
                  run_pandoc = TRUE)

cat("finish creating new daily report\n")
file.copy(from=paste0(format(Sys.time(), '%Y%m%d_%H'),"_CC_report.html"), to = "./Todays_Report/Today's report.html", overwrite=T)
sink() 
sink(type="message")

