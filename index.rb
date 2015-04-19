require 'byebug'
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
$count = 0
$thread_handle = nil
$twitter_client = setup_twitter_client
$media_urls = Queue.new
$url_history = Set.new
$topics = ["fashion"]

def start_listening(topics = [])
    if topics.empty?
        topics = $topics
    end
    $t_start = Time.now.to_f
    $thread_handle = Thread.new do
        loop do
            $twitter_client.filter(track: topics.join(",")) do |object|
                if not $thread_handle.alive?
                    return
                end

                tweet = object if object.is_a?(Twitter::Tweet) 
                if tweet.media? and not tweet.possibly_sensitive?
                    had_photo_and_not_duplicate = false
                    tweet.media.each do |m|
                        if m.is_a?(Twitter::Media::Photo) and not $url_history.include?(m.media_url)
                            had_photo_and_not_duplicate = true
                            $media_urls << m.media_url
                            $url_history.add(m.media_url)
                        end
                    end

                    if had_photo_and_not_duplicate
                        $count += 1
                    end
                end
            end
        end
    end
end

def stop_listening
    $t_acc += Time.now.to_f - $t_start
    Thread.kill($thread_handle)
end

def total_time
    running_time = Time.now.to_f - $t_start
    return $t_acc + running_time
end

post '/start_listening' do
    start_listening()
end

get '/stop_listening' do
    stop_listening
end

get '/get_running_average' do
    sleep(0.1)
    "#{($count / total_time).round(2)}"
end

get '/get_image' do
    "#{$media_urls.pop}"
end

post '/set_topic_while_running' do
    stop_listening
    sleep(0.5)
    $media_urls.clear
    start_listening([params["topic_text_field"]])
end

post '/set_topic' do
    $topics = [params["topic_text_field"]]
end

get '/' do 
    erb :index
end
