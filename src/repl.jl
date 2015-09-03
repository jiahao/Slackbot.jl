#This REPL requires:
# - a Slack Outgoing WebHooks integration, and
# - a Slack Incoming WebHooks integration

#Print debugging information to console?
DEBUG = false

#Replace this with your Slack token for your outgoing webhook
TOKEN = ""

#Replace this with your Webhook URL for your incoming webhook
INHOOK = "https://hooks.slack.com/services/"

#Add custom JSON entries to the returning payload to the incoming webhook
DEFAULTPAYLOAD = Dict()

#Load data from config.jl if present
#Search for config.jl in current working directory
configfile = joinpath(pwd(), "config.jl")
if isfile(configfile)
    include(configfile)
    DEBUG && info(string("Loading configuration from ", configfile))
end

isa(TOKEN, String) && (TOKEN = [TOKEN])

KOALA = """
　　　　　　　::.;;|
　　　　　　　::;;;|
　　　 r´""'''ヽー--､,,,,,.....__
　　　（:::::,,,..::;　　　 　　 .,,;;;:,..ヽ
　　　　ヾ,,.　　　　　　　 ';;;..:.:;; ）
　　　　　　| ｀ﾟ　l⌒l　ﾟ´ i.,,,,.ノ⌒"''''⌒ヽ
　　　　　　ト 　 l.,,,,.l　 ノY　　　　　 ,;;;;, ）
___　,ｨ,ｒ,ｧ　! ｀;ｰ‐--イ 　|　 ﾟ.ｒ‐t. ･ ｒ,ノ
ト ｀"　ｲ-┴''´""　;;;（"^''ヽ, ゝｲ　.ノ
ゝー-､,,　　　　　　　 ヾ､　　""'⌒ヽ､
　　　　 "''ゝ　　　　　　　ヽ　　 　 　 |
　　　　　 /'""　　　　　 　 |　　　　 　|
　　　　　|　　　　　　 　 r ､(　　　　　.j
　　　　<ヽi　　　　　 　 ゝ　　　　　 ノ
　　　　ゝ　　　　　 　　　 しイ⌒'""
　　　　　ヽ,,,ノ;;人,,,,,__,,......ノ
　　　　　　::;;;:|
　　　　　　:::;;;;|
"""
#####################

using Requests
using Morsel

app = Morsel.app()

#For debugging purposes, add an escape hatch to terminate current Julia
#instance if its internal state gets too hairy
DEBUG && route(app, GET | POST | PUT, "/reboot") do req, res
    exit(1)
end

route(app, GET | POST | PUT, "/") do req, res
    mycmd = ""
    channelname = "general"
    output, color, username = try
        DEBUG && info(string("Received HTTP packet with data\n", repr(req.state[:data]), "\n"))
        data = req.state[:data]

        (haskey(data, "token") && any(data["token"] .== TOKEN)) || error("Invalid Slack token")
        channelname = bytestring(data["channel_name"])
        username = bytestring(data["user_name"])

        if haskey(data, "text")
            cmdstart = if haskey(data, "trigger_word")
                length(data["trigger_word"])+2
            else#if haskey(data, "command")
                1
	        end
            mycmd = bytestring(strip(data["text"][cmdstart:end]))

            if length(mycmd)>=6 && mycmd[1:3] == mycmd[end-2:end] == "```"
                #Strip triple backquotes from start and end if present
                DEBUG && info("Removing triple backquotes")
                mycmd = mycmd[4:end-3]
            elseif length(mycmd)>=2 && mycmd[1] == mycmd[end] == '`'
                #Strip single backquotes from start and end if present
                DEBUG && info("Removing single backquotes")
                mycmd = mycmd[2:end-1]
            end

            #Unescape HTML entities produced by Slack
            mycmd = replace(mycmd, "&gt;", ">")
            mycmd = replace(mycmd, "&lt;", "<")
            mycmd = replace(mycmd, "&amp;", "&")

            #Replace smart quotes
            mycmd = replace(mycmd, "â\u80\u009c", "\"")
            mycmd = replace(mycmd, "â\u80\u9d", "\"")
            mycmd = replace(mycmd, "â\u80\u0098", "'")
            mycmd = replace(mycmd, "â\u80\u99", "'")

            status = "good"
            cmdout = ""
            try
                cmdout = string(eval(parse(mycmd)))
            catch exc
                io = IOBuffer()
                Base.showerror(io, exc, catch_backtrace())
                status = "danger"
                cmdout = takebuf_string(io)
            end

            mycmd == "koala" && (cmdout = KOALA)
            (cmdout, status, username)
        else
            ("Could not recognize input", "danger", username)
        end
    catch exc
        io = IOBuffer()
        Base.showerror(io, exc, catch_backtrace())
        (takebuf_string(io), "danger")
    end

    payload = merge(DEFAULTPAYLOAD, Dict("channel"=>"#"*channelname,
           "attachments" => [
              Dict("title"=>"Julia input from "*username, "text"=>mycmd, "fallback"=>mycmd),
              Dict("title"=>"Julia output", "color"=>color, "text"=>output, "fallback"=>output)
    ]))

    DEBUG && info(string("Posting to URL ", INHOOK, " the JSON payload:\n", payload))
    Requests.post(INHOOK; json=payload)
end

start(app, 8000)
