# defmodule Pisq.Workers.GameSupervisor do
#   use DynamicSupervisor
#   alias Pisq.Workers.Game, as: Game

#   def start_link(init_arg) do
#     DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
#   end

#   @impl true
#   def init(_init_arg) do
#     DynamicSupervisor.init(strategy: :one_for_one)
#   end

#   def start_game() do
#     uuids = create_game_uuids()
#     spec = {Game, uuids}
#     {:ok, game_pid} = DynamicSupervisor.start_child(__MODULE__, spec)
#     add_uuids_to_ets(uuids, game_pid)
#     {:ok, uuids}
#   end

#   defp create_game_uuids() do
#     game_id = to_string(:rand.uniform(Application.get_env(:pisq, :max_id_number)))
#     spectator_id = to_string(:rand.uniform(Application.get_env(:pisq, :max_id_number)))
#     crosses_id = to_string(:rand.uniform(Application.get_env(:pisq, :max_id_number)))
#     circles_id = to_string(:rand.uniform(Application.get_env(:pisq, :max_id_number)))
#     %{
#       game_id: game_id,
#       spectator_id: spectator_id,
#       crosses_id: crosses_id,
#       circles_id: circles_id
#     }
#   end

#   defp add_uuids_to_ets(
#     uuids,
#     game_pid
#   ) do
#     game_pid_store = Application.get_env(:pisq, :game_pid_store)
#     for {_, uuid} <- uuids do
#       :ets.insert(game_pid_store, {uuid, game_pid})
#     end
#   end
# end
