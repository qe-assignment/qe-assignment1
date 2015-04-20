$(function() {
    console.log("log")
});


$("#topic_form").submit(function(e) {
    if (listening) {
        $.ajax({
            method: "POST",
            url: "set_topic_while_running",
            data: $( this ).serialize()
        })
    }
    else {
        $.ajax({
            method: "POST",
            url: "set_topic",
            data: $( this ).serialize()
        })
        }
    e.preventDefault()
})

var update_image = function(url)
{
    var last_url = $("#newest_image").attr("src")
    $("#newest_image").attr("src",url)
    if (last_url) {
        $("#thumbnails").prepend("<img src='" + last_url + "'/>")
        $("#thumbnails").children().last().remove()
    }
}

var update_male_count = function(count)
{
    $("#male_count").text("Male count: " + count)
}

var update_female_count = function(count)
{
    $("#female_count").text("Female count: " + count)
}

var update_running_average = function(avg)
{
    $("#running_average").text("Running average: " + avg + " tweets/s")
}

var listening = false
var start_listening = function()
{
    listening = !listening
    if (listening) {
        $("#start_button").text("Stop listening")
        var topic = $("#topic").attr("value")
        $.ajax({url: "start_listening"})
    }
    else {
        $("#start_button").text("Start listening")
        $.ajax({ url: "stop_listening"})
    }
}

var image_ws = new WebSocket('ws://localhost:4567/register_image_ws')
image_ws.onmessage = function(message) {  
    update_image(message.data)
}

var running_average_ws = new WebSocket('ws://localhost:4567/register_running_average_ws')
running_average_ws.onmessage = function(message) {  
    update_running_average(message.data)
}

var male_count_ws = new WebSocket('ws://localhost:4567/register_male_count_ws')
male_count_ws.onmessage = function(message) {  
    update_male_count(message.data)
}

var female_count_ws = new WebSocket('ws://localhost:4567/register_female_count_ws')
female_count_ws.onmessage = function(message) {  
    update_female_count(message.data)
}
