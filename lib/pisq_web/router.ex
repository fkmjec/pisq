defmodule PisqWeb.Router do
  use PisqWeb, :router
  import Phoenix.LiveDashboard.Router

  alias PisqWeb.Plugs

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :fetch_live_flash
    plug :put_root_layout, {PisqWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PisqWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/admin/:game_id", GameController, :admin
    post "/create_game", GameController, :create_game
  end

  scope "/play", PisqWeb do
    pipe_through :browser
    alias Live.UserLive
    live "/:id", UserLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", PisqWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    # import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: PisqWeb.Telemetry
    end
  end
end
