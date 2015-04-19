$(function() {
    console.log("log")
});

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

var update_running_average = function()
{
    $.ajax({
        url: "get_running_average",
        contentType: "text/plain",
        success: function(avg) {
            $("#running_average").text("Running average: " + avg)
        }
    }).done(function() {
        if (listening) {
            update_running_average()
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
        $("#start_button").text("Stop listening")
        $.ajax({ url: "start_listening"})
    }
    else {
        $("#start_button").text("Start listening")
        $.ajax({ url: "stop_listening"})
    }
}
