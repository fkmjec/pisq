defmodule Pisq.Utils.StorageUtils do
  # The problem we are solving is having multiple keys in ETS that map to the same value (Game struct)
  # Current solution is to have the game under a single game_id and having other ids (players, spectators)
  # in a table which maps them to that game_id. This is sort of cumbersome and I do not like the approach,
  # but we shall stick with it for now.
  @game_id_lookup :game_id_lookup
  @game_store :game_store
  @end_of_table :"$end_of_table"

  def init_storage() do
    :ets.new(@game_id_lookup, [:set, :public, :named_table])
    :ets.new(@game_store, [:set, :public, :named_table])
  end

  defp store_user_id(user_id, game_id) do
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
    end
  end

  def update_game(game) do
    :ets.insert(@game_store, {game.user_ids.admin_id, game})
  end

  def cleanup_games(max_ttl) do
    first = :ets.first(@game_store)
    game_ids_to_remove = get_games_to_remove(first, %{}, max_ttl)
    for {id, _} <- game_ids_to_remove do
      :ets.delete(@game_store, id)
    end

    for {id, _} <- game_ids_to_remove do
      matches = :ets.match(@game_id_lookup, {:"$1", id})
      for [match] <- matches do
        :ets.delete(@game_id_lookup, match)
      end
    end
  end

  defp get_games_to_remove(@end_of_table, removed_games, _) do
    removed_games
  end

  defp get_games_to_remove(game_key, removed_games, max_ttl) do
    now = DateTime.to_unix(DateTime.utc_now())
    [{game_id, game}] = :ets.lookup(@game_store, game_key)
    if now - game.creation_timestamp > max_ttl do
      game_key = :ets.next(@game_store, game_key)
      removed_games = Map.put(removed_games, game_id, true)
      get_games_to_remove(game_key, removed_games, max_ttl)
    else
      game_key = :ets.next(@game_store, game_key)
      get_games_to_remove(game_key, removed_games, max_ttl)
    end
  end
end
