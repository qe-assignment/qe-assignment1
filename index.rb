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

$t_start = 0
$t_acc = 0
def total_time
    running_time = Time.now.to_f - $t_start
    return $t_acc + running_time
end


twitter_client = setup_twitter_client
media_urls = Queue.new

topics = ["fashion, selfie"]
count = 0
thread_handle = nil

get '/start_listening' do
    $t_start = Time.now.to_f
    thread_handle = Thread.new do
        loop do
            twitter_client.filter(track: topics.join(",")) do |object|
                # sleep(1)
                tweet = object if object.is_a?(Twitter::Tweet) 
                tweet.media.each do |m|
                    media_urls << m.media_url
                end
                count += tweet.media.length
            end
        end
    end
end

get '/stop_listening' do
    $t_acc += Time.now.to_f - $t_start
    Thread.kill(thread_handle)
end

get '/get_running_average' do
    sleep(0.1)
    "#{(count / total_time).round(2)}"
end

get '/get_image' do
    "#{media_urls.pop}"
end

get '/' do 
    erb :index
end
