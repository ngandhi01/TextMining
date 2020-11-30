"""
   clean.py

   The purpose of this script is to load tweets and clean them

   Input: 
      • aws_credentials.txt: has credentials for AWS account
      • import_tweets_name: Name of .json file (without .json extension) of raw tweets to import
      • export_tweets_name: Name to give to .csv file (without .csv extension) of cleaned tweets


"""

import argparse
import pandas as pd
import datetime
import os
import json

def standard_parse(tweets, set_name):

    """

        Returns tweets and relevant metadata in a DataFrame
        Input:
            • tweets: raw tweets
            • set_name: name to give to set of tweets (useful if parsing multiple bunches of tweets and then concatenating)
        Output:
            • df: df with relevant tweet data

    """
    
    data = {'created_at':[],\
       'text':[],\
       'tweet_id':[],\
       'user_screen_name':[],\
       'user_name':[],\
       'user_id':[],\
       'user_followers_count':[],\
       'user_following_count':[],\
       'user_statuses_count':[],\
       'user_likes_given_count':[],\
       'user_location':[],\
       'user_verified':[],\
       'user_description':[],\
       'tweet_lat':[],\
       'tweet_long':[],\
       'tweet_retweet_count':[],\
       'tweet_favorite_count':[],\
       'tweet_reply_count': [],\
       'tweet_hashtags':[],\
       'tweet_urls':[],\
       'tweet_media':[]}
    
    for tweet in tweets:
        if 'text' in tweet:
            if 'retweeted_status' not in tweet and 'RT @' not in tweet['text'] and not tweet['user']['verified']:
                data['created_at'].append(tweet['created_at'])

                if tweet['truncated']:
                    data['text'].append(tweet['extended_tweet']['full_text'])
                elif not tweet['truncated']:
                    data['text'].append(tweet['text'])

                data['tweet_id'].append(tweet['id_str'])
                data['user_screen_name'].append(tweet['user']['screen_name'])
                data['user_name'].append(tweet['user']['name'])
                data['user_id'].append(tweet['user']['id_str'])
                data['user_followers_count'].append(tweet['user']['followers_count'])
                data['user_following_count'].append(tweet['user']['friends_count'])
                data['user_statuses_count'].append(tweet['user']['statuses_count'])
                data['user_likes_given_count'].append(tweet['user']['favourites_count'])
                data['user_location'].append(tweet['user']['location'])
                data['user_verified'].append(tweet['user']['verified'])
                data['user_description'].append(tweet['user']['description'])

                if tweet['coordinates']:
                    data['tweet_lat'].append(tweet['coordinates']['coordinates'][1])
                    data['tweet_long'].append(tweet['coordinates']['coordinates'][0])
                elif not tweet['coordinates']:
                    data['tweet_lat'].append('NaN')
                    data['tweet_long'].append('NaN')

                data['tweet_retweet_count'].append(tweet['retweet_count'])
                data['tweet_favorite_count'].append(tweet['favorite_count'])
                data['tweet_reply_count'].append(tweet['reply_count'])
                data['tweet_hashtags'].append([hashtag['text'] for hashtag in tweet['entities']['hashtags']])
                data['tweet_urls'].append(list(url['expanded_url'] for url in tweet['entities']['urls']))

                if 'media' in tweet['entities']:
                    data['tweet_media'].append(list(url['media_url'] for url in tweet['entities']['media']))
                else:
                    data['tweet_media'].append('NaN')

    df = pd.DataFrame(data)

    df.drop_duplicates(subset = 'tweet_id', inplace = True) # drop duplicate tweets
    df.reset_index(drop = True, inplace = True)
    df['created_at'] = pd.to_datetime(df['created_at'])
    #df['set_id'] = set_name # column lets us define the source of the data
    
    return df


def main():

    # get params for scraping
    parser = argparse.ArgumentParser(description = "File for cleaning tweets and storing in AWS.")
    #parser.add_argument("aws_credentials", help = "Text file with AWS credentials (AWS access, AWS secret)")
    parser.add_argument("import_tweets_name", help = "Name of .json file (without .json extension) of raw tweets, to import from AWS", 
        default = "outrage_tweets_streamed_{}".format(datetime.datetime.today().strftime ('%d-%b-%Y'))) # assumes that there exists a .json file named by default of stream.py
    parser.add_argument("export_tweets_name", help = "Name to give to .csv file (without .csv extension) of cleaned tweets exported to AWS", 
        default = "outrage_tweets_streamed_cleaned_{}".format(datetime.datetime.today().strftime ('%d-%b-%Y'))) # named by current date, by default
    args = parser.parse_args()
    
    # set up access to AWS
    import_file_name = args.import_tweets_name
    export_file_name = args.export_tweets_name

    # load JSON tweets
    tweets = [json.loads(tweet) for tweet in open(import_file_name)]

    # clean files (standard_parse)
    try:
        print("Starting tweet parsing and cleaning....")
        df = standard_parse(tweets, args.export_tweets_name)
        df.to_csv(export_file_name, index = False, encoding = 'utf-8-sig')
        print("Finished parsing and cleaning tweets")
    except Exception as e:
        print("Error encountered with tweet parsing and cleaning. Please see error message: ")
        print(e)

    print("Script execution finished.")

if __name__ == "__main__":
    main()


