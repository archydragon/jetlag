defmodule Jetlag.Handler.Jabber do
  require Logger
  alias Romeo.Stanza
  alias Romeo.Connection, as: Conn
  use GenServer

  @server_name :handler_jabber

  def send(message) do
    GenServer.cast(@server_name, {:send, message})
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], name: @server_name)
  end

  def init(_) do
    config = Application.get_env(:jetlag, :config)
    jid = config["jabber_id"]
    password = config["jabber_password"]
    nickname = config["jabber_nickname"]
    conference = config["conference"]
    # if conference is password-protected, we need to add it as option
    conference_opts = case Map.has_key?(config, "conference_password") do
      true  -> [password: config["conference_password"]]
      false -> []
    end

    {:ok, pid} = Conn.start_link([jid: jid, password: password])
    :ok = Conn.send(pid, Stanza.join(conference, nickname, conference_opts))

    state = %{:pid => pid,
              :conference => conference,
              :nickname => nickname}
    {:ok, state}
  end

  # Handler for sending messages from Telegram to XMPP conference.
  def handle_cast({:send, message}, state) do
    conference = state[:conference]
    pid = state[:pid]
    Conn.send(pid, Stanza.groupchat(conference, message))
    {:noreply, state}
  end

  # All messages from XMPP connections are sent to this GenServer PID.
  # So this is a handler to retreive "message" stanzas with "body" attribute.
  def handle_info({:stanza, stanza}, state) do
    if Map.has_key?(stanza, :body) do
      from = stanza.from.resource
      # we don't need to send back our own messages retrieved from Telegram
      if from != state.nickname do
        # need this to_charlist because of UTF-8
        message = String.to_charlist(stanza.body)
        Jetlag.Handler.Telegram.send(from, message)
      end
    end
    {:noreply, state}
  end

  # And all other messages from the conference are just ignored.
  def handle_info(_, state) do
    {:noreply, state}
  end
  
end