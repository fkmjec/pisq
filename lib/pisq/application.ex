defmodule Pisq.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      #Pisq.Repo,
      # Start the Telemetry supervisor
      PisqWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Pisq.PubSub},
      # Start the Endpoint (http/https)
      PisqWeb.Endpoint,
      {Registry, keys: :unique, name: GameRegistry},
      {Pisq.Workers.GameSupervisor, name: Pisq.GameSupervisor, strategy: :one_for_one}
      # Start a worker by calling: Pisq.Worker.start_link(arg)
      # {Pisq.Worker, arg}
    ] 
    # create a ETS store for looking up procces PIDs.
    # we're using ETS since it is simple and fast. The idiomatic way
    # would probably be to use a Registry, but we don't mind the public
    # state that much.
    game_pid_store = Application.get_env(:pisq, :game_pid_store)
    :ets.new(game_pid_store, [:set, :public, :named_table])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pisq.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PisqWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
