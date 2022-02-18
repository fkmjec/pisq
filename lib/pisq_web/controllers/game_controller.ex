defmodule PisqWeb.GameController do
  use PisqWeb, :controller
  alias Pisq.Workers.GameSupervisor, as: GameSupervisor
  alias Pisq.Utils.GameUtils, as: GameUtils

  def create_game(conn, _params) do
    # create a new game
    {:ok, uuids} = GameSupervisor.start_game()
    # redirect to the game admin page
    redirect(conn, to: Routes.game_path(conn, :admin, uuids[:game_id]))
  end

  def admin(conn, %{"game_id" => game_id }) do
    game_pid = GameUtils.get_game_pid(game_id)
    case game_pid do
      :error ->
        conn
        |> put_status(:not_found)
        |> put_view(PisqWeb.ErrorView)
        |> render(:"404")
      _ ->
        case GenServer.call(game_pid, {:get_conn_details, %{game_id: game_id}}) do
          {:ok, conn_details} ->
            render(conn, "admin.html", game_id: game_id, conn_details: conn_details)
          {:error, _message} ->
            conn
            |> put_status(:not_found)
            |> put_view(PisqWeb.ErrorView)
            |> render(:"404")
            end
      end
  end
end
