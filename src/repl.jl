#This REPL requires:
# - a Slack Outgoing WebHooks integration, and
# - a Slack Incoming WebHooks integration

#Replace this with your Slack token for your outgoing webhook
const TOKEN = ""

#Replace this with your Webhook URL for your incoming webhook
const INHOOK = "https://hooks.slack.com/services/"

#####################

using Requests
using Morsel

app = Morsel.app()

route(app, GET | POST | PUT, "/") do req, res
    mycmd = ""
    channelname = "bots"
    output, color = try
    show(req.state[:data])
        data = req.state[:data]
        (haskey(data, "token") && data["token"] == TOKEN) || error("Invalid Slack token")
        channelname = data["channel_name"]
        username = data["user_name"]

        if haskey(data, "text")
            cmdstart = length(data["trigger_word"])+1
            mycmd = data["text"][cmdstart:end]
            try
                string(eval(parse(mycmd))), "good"
            catch exc
                io = IOBuffer()
                Base.show_backtrace(io, catch_backtrace())
                string("ERROR: ", exc, "\n", takebuf_string(io)), "danger"
            end
        else
            "Could not recognize input", "danger"
        end
    catch exc
        io = IOBuffer()
        Base.show_backtrace(io, catch_backtrace())
        string("ERROR: ", exc, "\n", takebuf_string(io)), "danger"
    end
    Requests.post(INHOOK;
        json=Dict("channel"=>"#"*channelname,
           #"username"=>"juliatan", #Custom bot user name
           #"icon_emoji"=>":juliatan:", #Custom bot icon
           "attachments" => [
              Dict("title"=>"Julia input", "text"=>mycmd, "fallback"=>mycmd),
              Dict("title"=>"Julia output", "color"=>color, "text"=>output, "fallback"=>output)
    ]))
end

start(app, 8000)
