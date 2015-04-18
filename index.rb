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
media_urls = Queue.new

topics = ["fashion, selfie"]
thread_handle = nil

get '/start_listening' do
    thread_handle = Thread.new do
        loop do
            twitter_client.filter(track: topics.join(",")) do |object|
                # sleep(1)
                tweet = object if object.is_a?(Twitter::Tweet) 
                tweet.media.each do |m|
                    media_urls << m.media_url
                end
            end
        end
    end
end

get '/stop_listening' do
    Thread.kill(thread_handle)
end

get '/get_image' do
    "#{media_urls.pop}"
end

get '/' do 
    erb :index
end
