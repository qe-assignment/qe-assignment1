require 'sinatra'
require 'sinatra-websocket'
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
$thread = nil
$twitter_client = setup_twitter_client
$facepp_client = setup_facepp_client
$url_history = Set.new
$topics = ["fashion"]
$image_ws = nil
$running_average_ws = nil
$male_count_ws = nil
$female_count_ws = nil

def start_listening(topics = [])
    if topics.empty?
        topics = $topics
    end
    $t_start = Time.now.to_f
    $thread = Thread.new do
        begin
            $twitter_client.filter(track: topics.join(",")) do |object|

                if not $thread.alive?
                    return
                end

                tweet = object if object.is_a?(Twitter::Tweet)
                tweet = object if object.is_a?(Twitter::Tweet) 
                if tweet.media? and not tweet.possibly_sensitive?
                    tweet.media.each do |m|
                        if m.is_a?(Twitter::Media::Photo) and not $url_history.include?(m.media_url.to_s)
                            response = $facepp_client.detection.detect(url: m.media_url.to_s)
                            response["face"].each do |face|
                                if face["attribute"]["gender"]["value"] == "Male"
                                    $male_count += 1
                                    Thread.new do
                                        $male_count_ws.send($male_count.to_s)
                                    end
                                elsif face["attribute"]["gender"]["value"] == "Female"
                                    $female_count += 1
                                    Thread.new do
                                        $female_count_ws.send($female_count.to_s)
                                    end
                                end
                            end

                            Thread.new do
                                $image_ws.send(m.media_url.to_s)
                            end
                            $count += 1
                            running_avg = ($count / total_time).round(2)
                            Thread.new do
                                $running_average_ws.send(running_avg.to_s)
                            end
                            $url_history.add(m.media_url.to_s)
                        end
                    end
                end
            end
        rescue Twitter::Error::TooManyRequests
            puts("TooManyRequests error")
            sleep 5
            retry
        end
    end
end

def stop_listening
    $t_acc += Time.now.to_f - $t_start
    Thread.kill($thread)
end

def total_time
    running_time = Time.now.to_f - $t_start
    return $t_acc + running_time
end

get '/register_image_ws' do
    request.websocket do |ws|
        ws.onopen do
            $image_ws = ws
        end
        ws.onclose do
            warn("websocket closed")
            settings.sockets.delete(ws)
        end
    end
end

get '/register_running_average_ws' do
    request.websocket do |ws|
        ws.onopen do
            $running_average_ws = ws
        end
        ws.onclose do
            warn("websocket closed")
            settings.sockets.delete(ws)
        end
    end
end

get '/register_male_count_ws' do
    request.websocket do |ws|
        ws.onopen do
            $male_count_ws = ws
        end
        ws.onclose do
            warn("websocket closed")
            settings.sockets.delete(ws)
        end
    end
end

get '/register_female_count_ws' do
    request.websocket do |ws|
        ws.onopen do
            $female_count_ws = ws
        end
        ws.onclose do
            warn("websocket closed")
            settings.sockets.delete(ws)
        end
    end
end

get '/start_listening' do
    start_listening
end

get '/stop_listening' do
    stop_listening
    $url_history.clear
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
