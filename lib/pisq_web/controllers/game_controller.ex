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
          render(conn, "admin.html", game_id: admin_id, conn_details: game.user_ids)
        else
          render(conn, "404.html")
        end
      {:error, _msg} ->
        render(conn, "404.html")
    end
  end
end
