defmodule PisqWeb.Live.UserLive do
  use PisqWeb, :live_view
  alias PisqWeb.Endpoint
  alias Pisq.Utils.GameUtils, as: GameUtils
  alias PisqWeb.Live.GameBoardComponent
  alias Pisq.Utils.StorageUtils, as: StorageUtils
  alias PisqWeb.Helpers, as: Helpers
  alias PisqWeb.GameNotFoundError

  @module "UserLive"

  # create the data to send to the client
  defp create_client_state(user_id, game) do
    board = game.board
    winner = game.winner
    user_type = GameUtils.get_user_type(user_id, game)
    can_play = GameUtils.can_play(user_type, game)
    %{
      user_type: user_type,
      board: board,
      winner: winner,
      winning_positions: game.winning_positions,
      can_play: can_play,
      page_title: get_page_title(user_type, user_id)
    }
  end

  defp update_state(id) do
    game = case StorageUtils.get_game(id) do
      {:ok, game} -> game
      {:error, _msg} -> raise PisqWeb.GameNotFoundError, "Game not found"
    end
    client_state = create_client_state(id, game)
    {game, client_state}
  end

  def render(assigns) do
    ~L"""
    <div class="section">
    <h1 class="title is-4 has-text-centered"><%= get_player_title_text(@user_type) %></h1>
      <span class="<%= Helpers.hide_when(@winner == nil) %>">
        <h1 class="subtitle is-3">Skvělá hra!</h1>
        <p>
        Tentokrát vyhrál hráč hrající za <%= get_winner_text(@winner) %>! Gratulujeme!
        Pro další hru se vydejte na <a href="<%= Routes.page_path(@socket, :index) %>">hlavní stránku</a>.
        </p>
      </span>
      <%= live_component @socket, GameBoardComponent, board: @board, can_play: @can_play, winning_positions: @winning_positions %>
    </div>
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
        put_flash(socket, :info, "Křížky vyhrály!")
      client_state.winner == :circles ->
        put_flash(socket, :info, "Kolečka vyhrály!")
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

  defp get_winner_text(winner) do
    case winner do
      :crosses -> "křížky"
      :circles -> "kolečka"
      :nil -> ""
    end
  end

  defp get_player_title_text(user_type) do
    case user_type do
      :crosses -> "Hraješ za křížky!"
      :circles -> "Hraješ za kolečka!"
      _ -> "Jen sleduješ hru!"
    end
  end

  defp get_page_title(user_type, user_id) do
    case user_type do
      :crosses -> "Křížky - #{user_id}"
      :circles -> "Kolečka - #{user_id}"
      _ -> "Pozorovatel - #{user_id}"
    end
  end
end
