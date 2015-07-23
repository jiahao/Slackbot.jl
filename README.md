# Slackbot.jl

A Julia REPL that interacts with Slack.com's webhook integration.

WARNING: Use at your own risk. This is a very naive, insecure bot that is meant more as proof of concept than for production use.

## Setup

1. Set up a Slack Incoming WebHook and a Slack Outgoing WebHook.

2. Create a `config.jl` in this directory that contains the following entries:

  - `TOKEN = "..." #Replace this with your Slack token for your outgoing webhook`
  - `INHOOK = "https://hooks.slack.com/services/..." #Replace this with your Webhook URL for your incoming webhook`
  - (Optional) `DEBUG = true #Print debugging information to console`
  - (Optional) `DEFAULTPAYLOAD = Dict(
    #Add custom JSON entries to the returning payload to the incoming webhook
    "username"=>"juliatan",
    "icon_emoji"=>":juliatan:"
)
`

3. Make sure that [`Morsel.jl`](https://github.com/JuliaWeb/Morsel.jl) is installed in Julia.

4. Run the `script/jl.sh` 

## Example of use

If you set up `jl` as the trigger word for your Slack Outgoing WebHook, you can write in a Slack channel

```
jl 2+2
```

and the bot will post
```
Julia input
2+2

Julia output
4
```

You can also encase the command sent after the trigger word in single backquotes or triple backquotes.

## The reboot escape hatch

It's quite possible to bork the entire state of the current Julia session. When this happens, and if you set `DEBUG = true`, then sending a HTTP POST to `/reboot` causes the current Julia instance to terminate, in effect restarting Slackbot.jl.
