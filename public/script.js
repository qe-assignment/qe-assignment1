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

var update_image = function()
{
    var last_src = ""

    $.ajax({
        url: "get_image",
        contentType: "text/plain",
        success: function(src) {
            $("#newest_image").attr("src",src)
            last_src = $("#newest_image").attr("src")
            if (last_src) {
                $("#thumbnails").prepend("<img src='" + last_src + "'/>")
                $("#thumbnails").children().last().remove()
            }
        }
    }).done(function() {
        if (listening) {
            update_image()
        }
    })
}

var update_male_count = function()
{
    $.ajax({
        url: "get_male_count",
        contentType: "text/plain",
        success: function(count) {
            $("#male_count").text("Male count: " + count)
        }
    }).done(function() {
        if (listening) {
            setTimeout('update_male_count()', 1000)
        }
    })
}

var update_female_count = function()
{
    $.ajax({
        url: "get_female_count",
        contentType: "text/plain",
        success: function(count) {
            $("#female_count").text("Female count: " + count)
        }
    }).done(function() {
        if (listening) {
            setTimeout('update_female_count()', 1000)
        }
    })
}

var update_running_average = function()
{
    $.ajax({
        url: "get_running_average",
        contentType: "text/plain",
        success: function(avg) {
            $("#running_average").text("Running average: " + avg + " tweets/s")
        }
    }).done(function() {
        if (listening) {
            setTimeout('update_running_average()', 100)
        }
    })
}

var listening = false
var start_listening = function()
{
    listening = !listening
    if (listening) {
        update_image()
        update_running_average()
        update_male_count()
        update_female_count()
        $("#start_button").text("Stop listening")
        var topic = $("#topic").attr("value")
        $.ajax({ 
            url: "start_listening",
            method: "POST",
            data: { "topic" : topic }
            })
    }
    else {
        $("#start_button").text("Start listening")
        $.ajax({ url: "stop_listening"})
    }
}
