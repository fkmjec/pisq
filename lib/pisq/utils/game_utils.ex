defmodule Pisq.Utils.GameUtils do
  # defp get_player_type(id) do
  #   pid = get_game_pid(id)
  #   GenServer.call(pid, {:get_player_type, id})
  # end

  # defp get_winner(id) do
  #   pid = get_game_pid(id)
  #   GenServer.call(pid, :get_winner)
  # end

  def can_play(user_id, game) do
    game.current_player == user_id and game.winner == nil
  end

  def is_field_available(board, {x, y}) do
    Map.has_key?(board, {x, y})
  end

  # verify if a side has won by placing a symbol at coordinates coords
  def verify_win(board, coords) do
    check_left_to_right(board, coords) or check_up_down(board, coords) or check_diagonals(board, coords)
  end

  defp check_left_to_right(board, {x, y}) do
    winning_count = Application.get_env(:pisq, :winning_symbol_count)
    Enum.any?(-(winning_count - 1)..0, fn dx -> check_row(board, {x + dx, y}) end)
  end

  defp check_up_down(board, {x, y}) do
    winning_count = Application.get_env(:pisq, :winning_symbol_count)
    Enum.any?(-(winning_count - 1)..0, fn dy -> check_column(board, {x, y + dy}) end)
  end

  defp check_diagonals(board, {x, y}) do
    winning_count = Application.get_env(:pisq, :winning_symbol_count)
    Enum.any?(-(winning_count - 1)..0, fn d -> check_diagonal(board, {x + d, y + d}) end)
  end


  defp check_row(board, {sx, sy} = starting_coords) do
    winning_count = Application.get_env(:pisq, :winning_symbol_count)
    starting_symbol = board[starting_coords]
    Enum.all?(0..winning_count - 1, fn dx -> board[{sx + dx, sy}] == starting_symbol end)
  end

  defp check_column(board, {sx, sy} = starting_coords) do
    winning_count = Application.get_env(:pisq, :winning_symbol_count)
    starting_symbol = board[starting_coords]
    Enum.all?(0..winning_count - 1, fn dy -> board[{sx, sy + dy}] == starting_symbol end)
  end

  defp check_diagonal(board, {sx, sy} = starting_coords) do
    winning_count = Application.get_env(:pisq, :winning_symbol_count)
    starting_symbol = board[starting_coords]
    Enum.all?(0..winning_count - 1, fn d -> board[{sx + d, sy + d}] == starting_symbol end)
  end

  def can_place_symbol?(board, x, y) do
    not out_of_bounds?(x, y) and board[{x, y}] == nil
  end

  def out_of_bounds?(x, y) do
    x < 0 or y < 0 or x >= Application.get_env(:pisq, :board_x) or x >= Application.get_env(:pisq, :board_y)
  end
end
