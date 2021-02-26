import requests
import json

def get_past_tweets(bearer_token, search_terms=["genomics", "variants"], start_date="20200101", end_date="20200103", max_results=100):
    
    """
        Uses Twitter Premium API, with Historical Search Full Archive endpoint, to get past tweets
        
        Args:
            • search_terms: list of terms to look up (type:list)
            • start_date: start date, in the format YYYYMMDD (type:str)
            • end_date: end_date, in the format YYYYMMDD (type:str)
            • bearer_token: long string containing bearer token creds for application (type:str)
            • max_results: maximum # of results to return (default: 100) (type: int)
            
        Returns list of tweet objects. Each item in the list is a tweet object, and the 
        text of the tweet can be accessed using the "text" key. 
        
        e.g., 
            for tweet in tweet_list:
                print(tweet["text"])
    """
    
    if type(start_date) != str or type(end_date) != str:
        raise Exception("The start and end dates need to be strings in the format YYYYMMDD")
    
    if len(start_date) != 8 or len(end_date) != 8:
        raise Exception("The start and end dates have the wrong length. They must be in the format YYYYMMDD")
        
    if len(search_terms) < 1:
        raise Exception("Need at least 1 term to look up")
        
    # set up params for request
    endpoint = "https://api.twitter.com/1.1/tweets/search/fullarchive/dev.json"
    headers = {"Authorization":f"Bearer {bearer_token}", "Content-Type": "application/json"}
    
    query_str = search_terms[0]
    
    for idx in range(1, len(search_terms)):
        query_str += f" OR {search_terms[idx]}"
        
    
    start = start_date + "0000"
    end = end_date + "0000"
        
    data_query = '{"query":"(' + query_str + ')", "fromDate": "' + start + '", "toDate": "' + end + '", "maxResults":"' + str(max_results) + '"}'

    # send request
    response = requests.post(endpoint,data=data_query,headers=headers).json()
    
    # print results, for ease of viewing
    print(json.dumps(response, indent = 2))
    
    # return results, as list of tweets
    tweet_list = response["results"]
    return tweet_list

### Example Implementation ####
new_tweets = get_past_tweets(bearer_token)