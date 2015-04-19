require 'byebug'
require 'sinatra'
require 'twitter'
require 'json'
require 'facepp'

def setup_twitter_client
    file = File.open('twitter-keys.json', 'r')
    keys = JSON.load(file)
    file.close

    client = Twitter::Streaming::Client.new do |config|
        config.consumer_key        = keys["consumer_key"]
        config.consumer_secret     = keys["consumer_secret"]
        config.access_token        = keys["access_token"]
        config.access_token_secret = keys["access_token_secret"]
    end

    return client
end

def setup_facepp_client
    file = File.open('facepp-keys.json', 'r')
    keys = JSON.load(file)
    file.close

    client = FacePP.new(keys["api_key"], keys["api_secret"])

    return client
end

$t_start = 0
$t_acc = 0
$count = 0
$male_count = 0
$female_count = 0
$thread_handle = nil
$twitter_client = setup_twitter_client
$facepp_client = setup_facepp_client
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
                            response = $facepp_client.detection.detect(url: m.media_url)
                            response["face"].each do |face|
                                if face["attribute"]["gender"]["value"] == "Male"
                                    $male_count += 1
                                elsif face["attribute"]["gender"]["value"] == "Female"
                                    $female_count += 1
                                end
                            end

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
    $media_urls.clear
    $url_history.clear
end

get '/get_running_average' do
    "#{($count / total_time).round(2)}"
end

get '/get_male_count' do
    "#{$male_count}"
end

get '/get_female_count' do
    "#{$female_count}"
end

get '/get_image' do
    "#{$media_urls.pop}"
end

post '/set_topic_while_running' do
    stop_listening
    start_listening([params["topic_text_field"]])
end

post '/set_topic' do
    $topics = [params["topic_text_field"]]
end

get '/' do 
    erb :index
end
