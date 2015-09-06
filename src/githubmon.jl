#!/usr/bin/env julia

#Monitors a GitHub repo for push events to master

using Requests
using JSON

owner = "JuliaLang"
repo = "julia"

oldt = Dates.now() - Dates.Hour(24)
#msgs = ["GitHub reporting started $(Dates.now())"]
msgs = []
while true

    t = Dates.now(Dates.UTC)

    #HTTP time format: http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html
    httptimestamp = Dates.format(oldt, Dates.RFC1123Format)#*" GMT"

    packet = try
        get(URI("https://api.github.com/repos/$owner/$repo/events"),
            headers=Dict("If-Modified-Since"=>httptimestamp))
    catch
        @goto nexttime
    end

    channel = "#bots"
    status = "good"
    if packet.status == 304 #Not modified
        info("HTTP 304: Not modified")
    elseif packet.status != 200 #Anything other than OK
        status = "#6b85dd"
        push!(msgs, "Warning: HTTP $packet.status received from GitHub API")
    else
        response = bytestring(packet.data)

        events = try
            JSON.parse(response)
        catch exc
            status = "error"
            push!(msgs, "Error in parsing GitHub response")
            filename = "events-$(Dates.now()).json"
            open(filename, "w") do f
                print(f, response)
            end
            push!(msgs, "Saved to $filename")
            []
        end

        for event in events
            if event["type"] == "PushEvent"
                user = event["actor"]["login"]
                timestamp = event["created_at"]

                if Dates.DateTime(timestamp[1:end-1], Dates.ISODateTimeFormat) < oldt
                    continue
                end

                branch = event["payload"]["ref"]
                if branch == "refs/heads/master"

                    newhash = event["payload"]["head"]
                    oldhash = event["payload"]["before"]

                    newhashurl = "https://github.com/$owner/$repo/commit/"*newhash
                    oldhashurl = "https://github.com/$owner/$repo/commit/"*newhash

                    newhashs = newhash[1:7]
                    oldhashs = oldhash[1:7]

                    dsize = event["payload"]["size"]
                    ddsize = event["payload"]["distinct_size"]

                    userurl = "https://github.com/"*user
                    branchurl = "https://github.com/$owner/$repo/tree/master"

                    #Use local git repo to compute whether this change is a fast-forward
                    if isdir(repo) 
                        run(`git -C $repo fetch`)
                    else #Clone a fresh copy
                        run(`git clone https://github.com/$owner/$repo.git`)
                    end

                    #How many commits different are these?
                    ncommits = parse(Int, readall(pipeline(
                        `git -C $repo rev-list $oldhash ^$newhash`, `wc -l`)))
                    
                    if dsize==0 || ddsize==0 || ncommits > 0
                        #master HEAD changed with no new commits. Force push?
                        status = "#d66661"
                        channel = "#general" #General alert
                    else
                        status = "good"
                    end
                    push!(msgs, "$timestamp: <$userurl|$user> pushed <$oldhashurl|$oldhashs>...<$newhashurl|$newhashs> on <$branchurl|$owner/$repo/master>: $dsize commits ($ddsize distinct; $ncommits non fast-forward)")
                end
            end
        end
    end

    msg = join(msgs, "\n")
    if msg != ""
        info("$t: Posting to Slack:\n"*msg)
        response = post(URI("https://hooks.slack.com/services/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");
            json=Dict("channel"=>channel, "username"=>"Julia-tan", "icon_emoji"=>":juliatan:",
                "attachments" => [
                    Dict("title"=>":julia: GitHub push event",
                        "color"=>status,
                        "fallback"=>msg,
                        "text"=> msg)]))
        info(bytestring(response.data))
    else
        info("$t: Nothing to report")
    end

    msgs = []
    oldt = t
    @label nexttime
    sleep(120) #Wait before polling GitHub again
end

