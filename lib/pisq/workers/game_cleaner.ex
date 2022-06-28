defmodule Pisq.Workers.GameCleaner do
  use GenServer
  alias Pisq.Utils.StorageUtils, as: StorageUtils

  def start_link(_state) do
    max_game_ttl = Application.get_env(:pisq, :max_game_ttl)
    game_cleaning_interval = Application.get_env(:pisq, :game_cleaning_interval)
    state = %{max_game_ttl: max_game_ttl, game_cleaning_interval: game_cleaning_interval}
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    Process.send_after(self(), :cleanup, state.game_cleaning_interval * 1000)
    {:ok, state}
  end

  def handle_info(:cleanup, state) do
    Process.send_after(self(), :cleanup, state.game_cleaning_interval * 1000)
    StorageUtils.cleanup_games(state.max_game_ttl)
    {:noreply, state}
  end
end
