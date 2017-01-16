defmodule Jetlag.Handler.Telegram do
  require Logger
  use GenServer

  def send(from, message) do
    formatted = :io_lib.format("<~ts> ~ts", [from, message])
    GenServer.cast(:handler_telegram, {:send, formatted})
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], name: :handler_telegram)
  end

  def init(_) do
    config = Application.get_env(:jetlag, :config)
    chat_id = config["telegram_chat_id"]
    
    schedule()
    state = %{:offset => 0, :chat_id => chat_id}
    {:ok, state}
  end

  def handle_cast({:send, message}, state) do
    chat_id = state[:chat_id]
    Nadia.send_message(chat_id, message)
    {:noreply, state}
  end

  def handle_info(:fetch, state) do
    offset = state[:offset]
    # Sometimes we are getting an exception here, thanks Telegram API
    # 'Unexpected token at position 0: <'
    try do
      {:ok, updates} = Nadia.get_updates(limit: 5, offset: offset)
    rescue Poison.SyntaxError ->
      updates = []
    end
    new_offset = process_updates(updates, offset)
    schedule()
    {:noreply, %{state | :offset => new_offset}}
  end

  defp schedule() do
    Process.send_after(self(), :fetch, 1000)
  end

  defp process_updates([], offset) do
    offset
  end

  defp process_updates([update | tail], _offset) do
    new_offset = update.update_id + 1
    text = update.message.text
    Logger.warn(:io_lib.format("message: ~p", [text]))
    Jetlag.Handler.Jabber.send(text)
    process_updates(tail, new_offset)
  end
  
end