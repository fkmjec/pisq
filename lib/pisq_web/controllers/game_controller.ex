defmodule PisqWeb.GameController do
  use PisqWeb, :controller
  alias Pisq.Utils.StorageUtils, as: StorageUtils
  alias Pisq.Game, as: Game

  def create_game(conn, params) do
    HTTPoison.start()
    recaptcha_response = params["g-recaptcha-response"]
    case verify_recaptcha(recaptcha_response) do
      true ->
        game = Game.create_game()
        redirect(conn, to: Routes.game_path(conn, :admin, game.user_ids.admin_id))
      _ ->
        redirect(conn, to: Routes.page_path(conn, :index))
    end
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

  defp verify_recaptcha(recaptcha_response) do
    secret_key = Application.get_env(:pisq, :recaptcha_secret)
    result = HTTPoison.post("https://www.google.com/recaptcha/api/siteverify", "secret=#{secret_key}&response=#{recaptcha_response}", [{"Content-Type", "application/x-www-form-urlencoded"}])
    case result do
      {:ok, response} ->
        body = Poison.decode!(response.body)
        body["success"]
      {:error, _} ->
        :error
    end
  end
end
