defmodule Pisq.Game do
  alias Pisq.Utils.StorageUtils, as: StorageUtils
  defstruct [
    creation_timestamp: nil,
    size_x: Application.get_env(:pisq, :board_x),
    size_y: Application.get_env(:pisq, :board_y),
    board: Map.new(),
    user_ids: nil,
    current_player: :crosses,
    winner: nil,
    winning_positions: nil
  ]

  def create_game() do
    game_id = generate_id()
    user_ids = %{
      admin_id: game_id,
      spectator_id: generate_id(),
      crosses_id: generate_id(),
      circles_id: generate_id()
    }
    game = %Pisq.Game{user_ids: user_ids, creation_timestamp: DateTime.to_unix(DateTime.utc_now())}
    case StorageUtils.store_game(game_id, game) do # can fail on conflicting game ids
      {:ok} -> game
      _ -> create_game()
    end
  end

  defp generate_id() do
    to_string(:rand.uniform(Application.get_env(:pisq, :max_id_number)))
  end
end
