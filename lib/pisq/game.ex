defmodule Pisq.Game do
  alias Pisq.Utils.StorageUtils, as: StorageUtils
  defstruct [
    size_x: Application.get_env(:pisq, :board_x),
    size_y: Application.get_env(:pisq, :board_y),
    board: Map.new(),
    turn_history: [],
    user_ids: nil,
    current_player: :crosses,
    winner: nil
  ]

  def create_game() do
    game_id = generate_id()
    user_ids = %{
      admin_id: game_id,
      spectator_id: generate_id(),
      crosses_id: generate_id(),
      circles_id: generate_id()
    }
    game = %Pisq.Game{user_ids: user_ids}
    case StorageUtils.store_game(game_id, game) do # can fail on conflicting game ids
      {:ok} -> game
      _ -> create_game() # FIXME: possible infinite recursion if the space of game ids is exhausted
    end
  end

  defp generate_id() do
    to_string(:rand.uniform(Application.get_env(:pisq, :max_id_number)))
  end
end