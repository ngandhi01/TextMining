"""
   Stream.py

   The purpose of this script is to stream tweets from Twitter

   Input: 
      • twitter_credentials.txt: has credentials for Twitter developer account
      • export_tweets_name: gives name of .json file to export upon streaming tweets
      • search_terms = search terms to use when scraping tweets

   This script will scrape tweets from Twitter and store in a .json file

"""

# working with Twitter API
import tweepy # using version 3.8.0
from tweepy import Stream
from tweepy import OAuthHandler
from tweepy.streaming import StreamListener

# helper functions, packages
import time as t
import csv
import json
import urllib
import re
import pandas as pd
import numpy as np
import argparse
import datetime
import sys


def authenticate(consumer_key, consumer_secret, access_token, access_secret):

   """
      Allows authentication with Twitter API, with relevant IDs
      Input: IDs
      Output: authentication, API access
   """

   auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
   auth.set_access_token(access_token, access_secret)

   api = tweepy.API(auth)

   try:
       api.verify_credentials()
       print("Authentication OK")
   except Exception as e:
       print("Error during authentication")
       print(e)

   return auth, api

# create a listener object
class Listener(StreamListener):

    """ 
    
    Creates an object that lets us listen for tweets from tweepy's StreamListener class
    and adds certain functionalities for saving the data to a .json file

    """

    # define class inheritance
    def __init__(self, max_num_tweets, tweet_count):
      # inherit StreamListener methods and attributes
      super().__init__()
      # add additional attributes
      self.max_num_tweets = max_num_tweets
      self.tweet_count = tweet_count

    # override on_data method from StreamListener
    def on_data(self, data):

        # write file
        try:

            # add to tweet count (lets you control how many tweets are scraped)
            #global max_num_tweets
            #global tweet_count

            #print(f"The max number of tweets is: {self.max_num_tweets} - scope: Listener()")
            #print(f"The current tweet count is: {self.tweet_count} - scope: Listener()")

            # update tweet count
            self.tweet_count += 1

            # stream as long as max tweet count isn't exceeded
            if self.tweet_count <= self.max_num_tweets:
               # every thousand tweets
               if self.tweet_count % 100 == 0:
                  print("{a} tweets scraped (out of maximum of {b} indicated).".format(a = self.tweet_count, b = self.max_num_tweets))
            else:
               print("Specified maximum number of tweets ({max})reached. Streaming halted.".format(max = self.max_num_tweets))
               #Stream.disconnect(self) # stop collecting tweets after max limit is reached
               return False
            
            # write data to a new file
            with open("new_tweets.json", 'a') as f:
               f.write(data)
               return True

        except BaseException as e:
            print('Error on data: %s' % str(e))
            t.sleep(5)
        
        return True
    
    
    # Handles minor errors
    def on_error(self, status):
        print(status)
        if status == 420:
            print('Exceeding rate limit / calls to Twitter API')
            # The streaming is halted in this instance, 
            #because Twitter applies penalities once the rate limit is breached
            return False      

def stream_tweets(search_terms, auth, max_tweets):

   """

      Creates a Listener (from tweepy's StreamListener class) to listen for tweets. 
      Exports a local .json file with the tweets.
      Input: 
         • search_terms: terms to search for during the stream (array)
         • auth: authentication from verification step
         • max_tweets: maximum # of tweets to stream

   """

   # initialize tweet counts
   tweet_count = 0
   max_num_tweets = max_tweets

   # create an instance of streaming, with the listener class above
   try:
      listener = Listener(max_num_tweets = max_num_tweets, tweet_count = tweet_count)
      twitter_stream = Stream(auth, listener, tweet_mode = 'extended', include_entities = True)
      print("Twitter stream initialized")

   except Exception as e:
      print("Problem with initializing Twitter stream")
      print(e)

   # start streaming, with parameters
   try:
      #print("Streaming in progressing. Searching for tweets with the following terms: " + search_terms)
      print(f"Streaming in progressing. Searching for tweets with the following terms: {str(search_terms)}")
      twitter_stream.filter(languages = ['en'], track = search_terms)
   except Exception as e:
      print("Problem with streaming in progress")
      print(f"Your error: {e}")
   finally:
      print("Twitter stream finished (successful if no exception has been raised.)")


def main():

   # get params
   parser = argparse.ArgumentParser(description = "File for streaming tweets and storing in AWS.")
   parser.add_argument("twitter_credentials", help = "Text file with Twitter developer credentials (consumer key, consumer secret, access key, access secret)")
   #parser.add_argument("aws_credentials", help = "Text file with AWS credentials (AWS access, AWS secret)")
   #parser.add_argument("export_tweets_name", help = "Name to give to .json file exported after Twitter streaming", 
   #   default = "outrage_tweets_streamed_{}".format(datetime.datetime.today().strftime ('%d-%b-%Y'))) # named by current date, by default
   parser.add_argument("max_tweet_count", help = "Maximum number of tweets to scrape", default = 250000, type = int)
   parser.add_argument("search_terms", help = "Search terms to use for Twitter streaming query.", nargs = "+") # unspecified # of possible keywords
   args = parser.parse_args()

   # get authentication
   consumer_key = ''
   consumer_secret = ''
   access_key = ''
   access_secret = ''

   with open(args.twitter_credentials, 'r') as twitter_creds:
      consumer_key = twitter_creds.readline().rstrip() # reads line, removes trailing whitespaces
      consumer_secret = twitter_creds.readline().rstrip()
      access_key = twitter_creds.readline().rstrip()
      access_secret = twitter_creds.readline().rstrip()

   try:
      auth, api = authenticate(consumer_key, consumer_secret, access_key, access_secret)
   except Exception as e:
      print("Authentication failed")
      print(e)

   # get number of tweets to stream, as well as an initialized count variable
   max_num_tweets = args.max_tweet_count
   tweet_count = 0

   # stream tweets
   try:
      print("The maximum number of tweets to scrape: " + str(max_num_tweets))
      stream_tweets(args.search_terms, auth, max_num_tweets)
      print("Tweet streaming step successful. {} tweets scraped. Tweets automatically stored in a new_tweets.json file, which is temporary".format(tweet_count))
      #print("The new file will now we stored to AWS")
   except Exception as e:
      print("Tweet streaming unsuccessful")
      print(e)

if __name__ == '__main__':
   main()









