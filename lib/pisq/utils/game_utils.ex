defmodule Pisq.Utils.GameUtils do
  def is_field_available(board, {x, y}) do
    Map.has_key?(board, {x, y})
  end

  def get_game_pid(id) do
    game_pid_store = Application.get_env(:pisq, :game_pid_store)
    [{_, pid}] = :ets.lookup(game_pid_store, id)
    pid
  end

  def place_symbol(id, x, y) do
    pid = get_game_pid(id)
    GenServer.call(pid, {:place_symbol, %{x: x, y: y, player_id: id}})
  end

  def get_game_board(id) do
    pid = get_game_pid(id)
    case GenServer.call(pid, :get_board) do
      {:ok, board} ->
        board
      {:error, _message} ->
        {:error, "Something real bad has happened, couldn't get game board"}
    end
  end

  def can_place_symbol?(board, x, y) do
    not out_of_bounds?(x, y) and board[{x, y}] == nil
  end

  def out_of_bounds?(x, y) do
    x < 0 or y < 0 or x >= Application.get_env(:pisq, :board_x) or x >= Application.get_env(:pisq, :board_y)
  end
end
