defmodule Pisq.Utils.GameUtils do
  def place_symbol(user_id, game, coords = {x, y}) do
    user_type = get_user_type(user_id, game)
    can_play = can_play(user_type, game)
    cond do
      can_play and can_place_symbol?(game.board, x, y) ->
        board = Map.put(game.board, coords, user_type)
        current_player = case user_type do
          :crosses -> :circles
          :circles -> :crosses
          _ -> raise "Unknown player type"
        end
        winner = case verify_win(board, coords) do
          true -> user_type
          false -> nil
        end
        {:ok, %{ game | board: board, current_player: current_player, winner: winner}}
      true ->
        {:error, "Either the user cannot play or the field is taken"}
    end
  end

  def get_user_type(user_id, game) do
    { user_type, _ } = Enum.find(game.user_ids, fn {_, uid} -> uid == user_id end)
    case user_type do
      :crosses_id -> :crosses
      :circles_id -> :circles
      :admin_id -> :admin
      :spectator_id -> :spectator
      _ -> raise "unknown player type"
    end
  end

  def can_play(user_type, game) do
    game.current_player == user_type and game.winner == nil
  end

  defp is_field_available(board, {x, y}) do
    not Map.has_key?(board, {x, y})
  end

  # verify if a side has won by placing a symbol at coordinates coords
  defp verify_win(board, coords) do
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

  defp can_place_symbol?(board, x, y) do
    not out_of_bounds?(x, y) and board[{x, y}] == nil
  end

  defp out_of_bounds?(x, y) do
    x < 0 or y < 0 or x >= Application.get_env(:pisq, :board_x) or x >= Application.get_env(:pisq, :board_y)
  end
end
