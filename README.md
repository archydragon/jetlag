# Jetlag

Jetlag is a gate to access XMPP (aka Jabber) conferences using Telegram client.
I wrote it because got tired to keep one more IM client running for those two
MUCs which were interesting for me.

Work principle: from XMPP end you look like a usual user who participate
the chat; from Telegram end it is just a bot who sends to you chat messages
from the MUC (no status updates or nickname changes at least in this version).

Right now Jetlag has very simple functionality (one application instance = one
link between one conference and one bot; no status updates or nickname changes
are supported) but if you have any ideas for improvements, don't hesitate to
write about them in issues/PRs :).

Can be run as Docker container, otherwise require Elixir 1.3 or newer to be
compiled.


## Required preparations

0. Register XMPP and Telgram accounts if you have no ones.
1. Access [@BotFather](https://telegram.me/BotFather) to register a new
   Telegram bot. Write down its API token.
2. (Some stupid magic starts here.) Write anything to your new bot using your
   Telegram client.
3. Do `curl -H "Content-Type: application/json" https://api.telegram.org/bot<YOUR_TOKEN_HERE>/getUpdates`
   (without <> around the token). Find `chat_id` parameter in the response and
   write it down. Unfortunately, right now there are no easy ways to get that
   ID for your account (maybe I need to write a bot for this purpose only, who
   knows).
4. Copy __jetlag.yml.sample__ to e.g. __jetlag-chatname.yml__ and update it
   with real configuration values. All options except `conference_password` are
   required.


## Compiling

Stand-alone:

    $ git clone https://github.com/Mendor/jetlag.git
    $ cd jetlag
    $ mix deps.get
    $ mix compile

With Docker:

    $ git clone https://github.com/Mendor/jetlag.git
    $ cd jetlag
    $ sudo docker build -t jetlag:0.1.0 .


## Running

Stand-alone:

    $ JETLAG_CONFIG_FILE=jetlag-chatname.yml mix run --no-halt

With Docker:

    $ sudo docker run -de "JETLAG_CONFIG_FILE=jetlag-chatname.yml" jetlag:0.1.0

Don't forget to replace `jetlag-chatname.yml` with your configuration file name.


## License

[MIT](https://opensource.org/licenses/MIT)
