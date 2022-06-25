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
        {winner, winning_positions} = case verify_win(board, coords) do
          {true, winning_positions} -> {user_type, winning_positions}
          {false, winning_positions}-> {nil, winning_positions}
        end
        {:ok, %{ game | board: board, current_player: current_player, winner: winner, winning_positions: winning_positions}}
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

  defp check_fields(board, start, diff, count) do
    starting_symbol = board[start]
    {won, winning_fields} = Enum.reduce(0..count-1, {true, Map.new}, fn d, {won, winning_fields} ->
      pos = add(start, multiply(d, diff))
      won = won and board[pos] == starting_symbol
      winning_fields = Map.put(winning_fields, pos, true)
      {won, winning_fields}
    end)
    case won do
      true -> {true, winning_fields}
      false -> {false, Map.new}
    end
  end

  defp add({u, v}, {x, y}) do
    {u + x, v + y}
  end

  defp multiply(scalar, {x, y}) do
    {scalar * x, scalar * y}
  end

  def verify_win(board, {x, y}) do
    winning_count = Application.get_env(:pisq, :winning_symbol_count)
    Enum.reduce(-(winning_count - 1)..0, {false, Map.new}, fn d, {won, winning_positions} ->
      {won_row, winning_row} = check_fields(board, {x + d, y}, {1, 0}, winning_count)
      {won_col, winning_col} = check_fields(board, {x, y + d}, {0, 1}, winning_count)
      {won_diag, winning_diag} = check_fields(board, {x + d, y + d}, {1, 1}, winning_count)
      won = won or won_row or won_col or won_diag
      winning_positions = Map.merge(winning_positions, winning_row)
      |> Map.merge(winning_col)
      |> Map.merge(winning_diag)
      {won, winning_positions}
    end)
  end

  defp can_place_symbol?(board, x, y) do
    not out_of_bounds?(x, y) and board[{x, y}] == nil
  end

  defp out_of_bounds?(x, y) do
    x < 0 or y < 0 or x >= Application.get_env(:pisq, :board_x) or x >= Application.get_env(:pisq, :board_y)
  end
end
