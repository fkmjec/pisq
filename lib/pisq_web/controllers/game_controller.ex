defmodule PisqWeb.GameController do
  use PisqWeb, :controller
  alias Pisq.Utils.StorageUtils, as: StorageUtils
  alias Pisq.Game, as: Game

  def create_game(conn, _params) do
    game = Game.create_game()
    redirect(conn, to: Routes.game_path(conn, :admin, game.user_ids.admin_id))
  end

  def admin(conn, %{"admin_id" => admin_id }) do
    case StorageUtils.get_game(admin_id) do
      {:ok, game} ->
        if game.user_ids.admin_id == admin_id do
          render(conn, "admin.html", page_title: "Admin hry #{admin_id}", game_id: admin_id, conn_details: game.user_ids)
        else
          conn
          |> put_view(PisqWeb.ErrorView)
          |> render("404.html")
        end
      {:error, _msg} ->
        conn
        |> put_view(PisqWeb.ErrorView)
        |> render("404.html")
    end
  end
end
