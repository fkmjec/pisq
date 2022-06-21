defmodule Pisq.Utils.StorageUtils do
  # The problem we are solving is having multiple keys in ETS that map to the same value (Game struct)
  # Current solution is to have the game under a single game_id and having other ids (players, spectators)
  # in a table which maps them to that game_id. This is sort of cumbersome and I do not like the approach,
  # but we shall stick with it for now.
  @game_id_lookup :game_id_lookup
  @game_store :game_store

  def init_storage() do
    :ets.new(@game_id_lookup, [:set, :public, :named_table])
    :ets.new(@game_store, [:set, :public, :named_table])
  end

  defp store_user_id(user_id, game_id) do
    # FIXME: what if user_ids collide?
    # for now we shall assume that it won't happen
    case :ets.insert(@game_id_lookup, {user_id, game_id}) do
      _ -> {:ok} # so that it has a consistent API
    end
  end

  defp get_game_id(user_id) do
    results = :ets.lookup(@game_id_lookup, user_id)
    if length(results) == 1 do
      [{_, game_id}] = results
      {:ok, game_id}
    else
      {:error, "No game corresponding to user ID"}
    end
  end

  def store_game(game_id, game) do
    case :ets.insert_new(@game_store, {game_id, game}) do
      true ->
        # create user_id -> game_id mapping
        for {_, id} <- game.user_ids do
          store_user_id(id, game_id)
        end
        {:ok}
      _ -> {:error, "Game with this ID already exists"}
    end
  end

  def get_game(user_id) do
    case get_game_id(user_id) do
      {:ok, game_id} ->
        [{_, game}] = :ets.lookup(@game_store, game_id)
        {:ok, game}
      {:error, msg} -> {:error, msg}
      _ -> raise "Unexpected result"
    end
  end
end
