defmodule Pisq.Utils.GameUtilsTest do
  use ExUnit.Case
  alias Pisq.Utils.GameUtils

  test "row gets detected" do
    start_pos = {0, 0}
    board_cross = create_row(start_pos, :cross)
    {won, _} = GameUtils.verify_win(board_cross, start_pos)
    assert won
  end

  test "column gets detected" do
    start_pos = {0, 0}
    board_cross = create_column(start_pos, :cross)
    {won, _} = GameUtils.verify_win(board_cross, start_pos)
    assert won
  end

  test "diagonal gets detected" do
    start_pos = {0, 0}
    board_cross = create_diagonal(start_pos, :cross)
    {won, _} = GameUtils.verify_win(board_cross, start_pos)
    assert won
  end

  defp create_row({sx, sy}, symbol) do
    winning_count = Application.get_env(:pisq, :winning_symbol_count)
    board = Enum.reduce(0..winning_count, Map.new, fn x, constructed_board ->
      Map.put(constructed_board, {sx + x, sy}, symbol)
    end)
  end

  defp create_column({sx, sy}, symbol) do
    winning_count = Application.get_env(:pisq, :winning_symbol_count)
    board = Enum.reduce(0..winning_count, Map.new, fn y, constructed_board ->
      Map.put(constructed_board, {sx, sy + y}, symbol)
    end)
  end

  defp create_diagonal({sx, sy}, symbol) do
    winning_count = Application.get_env(:pisq, :winning_symbol_count)
    board = Enum.reduce(0..winning_count, Map.new, fn x, constructed_board ->
      Map.put(constructed_board, {sx + x, sy + x}, symbol)
    end)
  end
end
