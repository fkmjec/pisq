defmodule PisqWeb.Live.UserLive do
  use PisqWeb, :live_view
  alias PisqWeb.Endpoint
  alias Pisq.Utils.GameUtils
  alias PisqWeb.Live.GameBoardComponent

  @module "UserLive"

#   defp topic(team_id), do: "team:#{team_id}"

  def render(assigns) do
    ~L"""
    <h3> User <%= @id %> </h3>
    <div class="container-fluid px-0">
    <%= live_component @socket, GameBoardComponent, board: @board %>
    """
  end

  def mount(params, _session, socket) do
    id = params["id"]
    game_state = GameUtils.get_game_state(id)

    socket = assign(socket, :id, id)
    |> assign(game_state)

    Endpoint.subscribe(id)
    {:ok, socket}
  end

  def handle_info(%{event: "board_update", payload: state}, socket) do
    {:noreply, assign(socket, state)}
  end

  def handle_info(%{event: "game_end", payload: state = %{winner: :circles}}, socket) do
    socket = put_flash(socket, :info, "Circles won!")
    {:noreply, assign(socket, state)}
  end

  def handle_info(%{event: "game_end", payload: state = %{winner: :crosses}}, socket) do
    socket = put_flash(socket, :info, "Crosses won!")
    {:noreply, assign(socket, state)}
  end

  def handle_event(
    "place_symbol",
    _,
    socket = %{ assigns: %{winner: winner}}
  ) when winner != nil do
    {:noreply, put_flash(socket, :error, "The game is over, #{winner} won!")}
  end


  def handle_event(
    "place_symbol",
    %{"x" => str_x, "y" => str_y},
    socket
  ) do
    { x, "" } = Integer.parse(str_x)
    { y, "" } = Integer.parse(str_y)
    id = socket.assigns.id
    case GameUtils.place_symbol(id, x, y) do
      {:ok, %{board: board}} -> {:noreply, assign(socket, :board, board)}
      {:error, message} ->
        socket = put_flash(socket, :error, message)
        {:noreply, socket} # TODO error handling
      _ -> {:noreply, socket} # should never happen
    end
  end

end
