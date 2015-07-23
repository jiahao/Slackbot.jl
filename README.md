# Slackbot.jl

A Julia REPL that interacts with Slack.com's webhook integration.

WARNING: Use at your own risk. This is a very naive, insecure bot that is meant more as proof of concept than for production use.

## How to use

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
