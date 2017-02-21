defmodule Jetlag.Handler.Telegram do
  require Logger
  use GenServer

  @server_name :handler_telegram

  def send(from, message) do
    formatted = "<#{from}> #{message}"
    GenServer.cast(@server_name, {:send, formatted})
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], name: @server_name)
  end

  def init(_) do
    config = Application.get_env(:jetlag, :config)
    chat_id = config["telegram_chat_id"]
    telegram_token = config["telegram_bot_token"]

    Application.put_env(:nadia, :token, telegram_token)
    # initiate API poller
    schedule()

    # "offset" means the earliest Telegram message ID we need to poll.
    # For the first poll we want to receive last 5 unread messages.
    # See Telegram API documentation for details.
    state = %{:offset => 0, :chat_id => chat_id}
    {:ok, state}
  end

  # Handler for sending messages to Telegram channel
  def handle_cast({:send, message}, state) do
    chat_id = state[:chat_id]
    Nadia.send_message(chat_id, message)
    {:noreply, state}
  end

  # API poller callback for new messages sent by Telegram user
  def handle_info(:poll, state) do
    offset = state[:offset]
    # Sometimes we are getting an exception here, thanks Telegram API
    # 'Unexpected token at position 0: <'
    {:ok, updates} = try do
      Nadia.get_updates(limit: 5, offset: offset)
    rescue Poison.SyntaxError ->
      {:ok, []}
    end
    new_offset = process_updates(updates, offset)
    schedule()
    {:noreply, %{state | :offset => new_offset}}
  end

  # API poller scheduler
  defp schedule() do
    Process.send_after(self(), :poll, 1000)
  end

  defp process_updates([], offset) do
    offset
  end

  defp process_updates([update | tail], _offset) do
    new_offset = update.update_id + 1
    # quote origin message if it was reply
    text = case update.message.reply_to_message do
      nil -> update.message.text
      _   -> "#{update.message.reply_to_message.text}\n#{update.message.text}"
    end
    Jetlag.Handler.Jabber.send(text)
    process_updates(tail, new_offset)
  end
  
end