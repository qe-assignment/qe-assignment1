require 'sinatra'
require 'twitter'
require 'json'

def setup_twitter_client
    file = File.read('twitter-keys.json')
    keys = JSON.load(file)
    client = Twitter::Streaming::Client.new do |config|
        config.consumer_key        = keys["consumer_key"]
        config.consumer_secret     = keys["consumer_secret"]
        config.access_token        = keys["access_token"]
        config.access_token_secret = keys["access_token_secret"]
    end

    return client
end

twitter_client = setup_twitter_client

topics = ["fashion"]
get '/' do 
    stream do |out|
            twitter_client.filter(track: topics.join(",")) do |object|
                tweet = object if object.is_a?(Twitter::Tweet) 
                out << tweet.text
            end
    end
end
