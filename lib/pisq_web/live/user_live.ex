defmodule PisqWeb.Live.UserLive do
  use PisqWeb, :live_view
  alias PisqWeb.Endpoint
  alias Pisq.Utils.GameUtils, as: GameUtils
  alias PisqWeb.Live.GameBoardComponent
  alias Pisq.Utils.StorageUtils, as: StorageUtils

  @module "UserLive"

  # create the data to send to the client
  defp create_client_state(user_id, game) do
    board = game.board
    winner = game.winner
    user_type = GameUtils.get_user_type(user_id, game)
    can_play = GameUtils.can_play(user_type, game)
    %{
      board: board,
      winner: winner,
      can_play: can_play
    }
  end

  defp update_state(id) do
    game = case StorageUtils.get_game(id) do
      {:ok, game} -> game
      {:error, _msg} -> raise "Not found" # TODO: make this not throw a 500
    end
    client_state = create_client_state(id, game)
    {game, client_state}
  end

  def render(assigns) do
    ~L"""
    <h3> User <%= @id %> </h3>
    <div class="container-fluid px-0">
    <%= live_component @socket, GameBoardComponent, board: @board, can_play: @can_play %>
    """
  end

  def mount(params, _session, socket) do
    id = params["id"]
    {game, client_state} = update_state(id)

    socket = assign(socket, :id, id)
    |> assign(client_state)

    Endpoint.subscribe(game.user_ids.admin_id)
    {:ok, socket}
  end

  def handle_info(%{event: "game_update"}, socket) do
    {_, client_state} = update_state(socket.assigns.id)
    socket = cond do
      client_state.winner == :crosses ->
        put_flash(socket, :info, "Crosses won!")
      client_state.winner == :circles ->
        put_flash(socket, :info, "Circles won!")
      true ->
        socket
    end
    {:noreply, assign(socket, client_state)}
  end

  def handle_event(
    "place_symbol",
    %{"x" => str_x, "y" => str_y},
    socket
  ) do
    { x, "" } = Integer.parse(str_x)
    { y, "" } = Integer.parse(str_y)
    id = socket.assigns.id
    {game, client_state} = update_state(id)
    socket = assign(socket, client_state)
    game = case GameUtils.place_symbol(id, game, {x, y}) do
      {:ok, new_game} -> new_game
      _ -> game
    end
    StorageUtils.update_game(game)
    {_, client_state} = update_state(id)
    socket = assign(socket, client_state)
    Endpoint.broadcast(game.user_ids.admin_id, "game_update", %{})
    {:noreply, socket}
  end
end
