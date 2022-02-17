defmodule Pisq.Workers.Game do
  use GenServer

  alias Pisq.Utils.GameUtils
  alias PisqWeb.Endpoint

  def start_link(uuids) do
    GenServer.start_link(__MODULE__, uuids, name: get_name(uuids[:game_id]))
  end

  def get_name(id) do
      {:via, Registry, {GameRegistry, "#{id}"}}
  end

  def init(%{
      game_id: game_id,
      spectator_id: spectator_id,
      crosses_id: crosses_id,
      circles_id: circles_id
    }
  ) do
    board = %{}
    current_player_id = crosses_id
    { :ok, %{
        board: board,
        current_player_id: current_player_id,
        crosses_id: crosses_id,
        circles_id: circles_id,
        game_id: game_id,
        spectator_id: spectator_id,
        game_over: false
      }
    }
  end

  def handle_call(
    {:get_conn_details, %{game_id: trying_id}},
    _from,
    state = %{game_id: game_id, crosses_id: crosses_id, circles_id: circles_id, spectator_id: spectator_id}
  ) do
    cond do
      trying_id == game_id ->
        {:reply, {:ok, %{crosses_id: crosses_id, circles_id: circles_id, spectator_id: spectator_id}}, state}
      true ->
        {:reply, {:error, "Wrong game id"}, state}
    end
  end

  def handle_call(:get_board, _from, state = %{board: board}) do
    {:reply, {:ok, board}, state}
  end

  def handle_call(:get_winner, _from, state = %{ game_over: false }) do
    {:reply, nil, state}
  end

  def handle_call(:get_winner, _from, state = %{ game_over: true, current_player_id: circles_id, circles_id: circles_id, crosses_id: crosses_id}) do
    {:reply, :crosses, state}
  end

  def handle_call(:get_winner, _from, state = %{ game_over: true, current_player_id: crosses_id, circles_id: circles_id, crosses_id: crosses_id}) do
    {:reply, :circles, state}
  end

  def handle_call({:get_player_type, crosses_id}, _from, state = state = %{ crosses_id: crosses_id}) do
    {:reply, :crosses, state}
  end

  def handle_call({:get_player_type, circles_id}, _from, state = state = %{ circles_id: circles_id}) do
    {:reply, :circles, state}
  end

  def handle_call({:get_player_type, spectator_id}, _from, state = state = %{ spectator_id: spectator_id}) do
    {:reply, :spectator, state}
  end

  # def handle_call(
  #   {:place_symbol, _},
  #   _from,
  #   state = %{
  #     game_over: true,
  #     current_player_id: circles_id,
  #     circles_id: circles_id,
  # }) do
  #   {:reply, {:error, "Game is over, crosses won!"}, state}
  # end

  # def handle_call(
  #   {:place_symbol, _},
  #   _from,
  #   state = %{
  #     game_over: true,
  #     current_player_id: crosses_id,
  #     crosses_id: crosses_id,
  # }) do
  #   {:reply, {:error, "Game is over, circles won!"}, state}
  # end

  # TODO untangle
  def handle_call(
    {:place_symbol, %{ x: x, y: y, player_id: player_id}},
    _from,
    state = %{
      board: board,
      current_player_id: current_player_id,
      crosses_id: crosses_id,
      circles_id: circles_id,
      spectator_id: spectator_id,
      game_over: false
    }
  ) do
    cond do
      !GameUtils.can_place_symbol?(board, x, y) ->
        {:reply, {:error, "Placing symbol on an invalid field"}, state}
      player_id == crosses_id and player_id == current_player_id ->
        board = Map.put(board, {x, y}, :cross)
        broadcast_board_change(board, crosses_id, circles_id, spectator_id)
        current_player_id = circles_id
        state = cond do
          GameUtils.verify_win(board, {x, y}) ->
            broadcast_game_end(:crosses, crosses_id, circles_id, spectator_id)
            %{state | board: board, current_player_id: current_player_id, game_over: true}
          true ->
            %{state | board: board, current_player_id: current_player_id}
        end
        {:reply, :ok, state}
      player_id == circles_id and player_id == current_player_id ->
        board = Map.put(board, {x, y}, :circle)
        broadcast_board_change(board, crosses_id, circles_id, spectator_id)
        current_player_id = crosses_id
        state = cond do
            GameUtils.verify_win(board, {x, y}) ->
              broadcast_game_end(:circles, crosses_id, circles_id, spectator_id)
              %{state | board: board, current_player_id: current_player_id, game_over: true}
            true ->
              %{state | board: board, current_player_id: current_player_id}
        end
        {:reply, :ok, state}
      true ->
        {:reply, {:error, "Invalid player id"}, state}
    end
  end

  # FIXME this looks pretty bad, can it be prettier?
  defp broadcast_board_change(board, crosses_id, circles_id, spectator_id) do
    Endpoint.broadcast_from(self(), crosses_id, "board_update", %{board: board})
    Endpoint.broadcast_from(self(), circles_id, "board_update", %{board: board})
    Endpoint.broadcast_from(self(), spectator_id, "board_update", %{board: board})
  end

  # FIXME this looks pretty bad, can it be prettier?
  defp broadcast_game_end(winner, crosses_id, circles_id, spectator_id) do
    Endpoint.broadcast_from(self(), crosses_id, "game_end", %{winner: winner})
    Endpoint.broadcast_from(self(), circles_id, "game_end", %{winner: winner})
    Endpoint.broadcast_from(self(), spectator_id, "game_end", %{winner: winner})
  end
end
