defmodule Jetlag.Handler.Jabber do
  require Logger
  alias Romeo.Stanza
  alias Romeo.Connection, as: Conn
  use GenServer

  def send(message) do
    GenServer.cast(:handler_jabber, {:send, message})
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], name: :handler_jabber)
  end

  def init(_) do
    config = Application.get_env(:jetlag, :config)
    jid = config["jabber_id"]
    password = config["jabber_password"]
    nickname = config["jabber_nickname"]
    conference = config["conference"]
    opts = case Map.has_key?(config, "conference_password") do
      true  -> [password: config["conference_password"]]
      false -> []
    end

    {:ok, pid} = Conn.start_link([jid: jid, password: password])
    :ok = Conn.send(pid, Stanza.join(conference, nickname, opts))

    state = %{:pid => pid,
              :conference => conference,
              :nickname => nickname}
    {:ok, state}
  end

  def handle_cast({:send, message}, state) do
    conference = state[:conference]
    pid = state[:pid]
    Conn.send(pid, Stanza.groupchat(conference, message))
    {:noreply, state}
  end

  def handle_info({:stanza, stanza}, state) do
    if Map.has_key?(stanza, :body) do
      from = stanza.from.resource
      message = String.to_charlist(stanza.body)
      # Logger.warn(:io_lib.format("stanza body: ~s", [message]))
      if from != state.nickname do
        Jetlag.Handler.Telegram.send(from, message)
      end
    end
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
  
end