defmodule Coderacer.Leaderboards do
  @moduledoc """
  The Leaderboards context for managing leaderboard entries and rankings.
  """

  import Ecto.Query, warn: false
  alias Coderacer.Repo

  alias Coderacer.Leaderboards.LeaderboardEntry
  alias Coderacer.Game.Session

  @doc """
  Creates a leaderboard entry.

  ## Examples

      iex> create_leaderboard_entry(%{field: value})
      {:ok, %LeaderboardEntry{}}

      iex> create_leaderboard_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_leaderboard_entry(attrs \\ %{}) do
    %LeaderboardEntry{}
    |> LeaderboardEntry.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets global leaderboard entries ordered by CPM descending.
  Limits to top N entries (default 10).
  """
  def get_global_leaderboard(limit \\ 10) do
    from(entry in LeaderboardEntry,
      join: session in Session,
      on: entry.session_id == session.id,
      order_by: [desc: entry.cpm, desc: entry.accuracy],
      limit: ^limit,
      select: %{
        player_name: entry.player_name,
        cpm: entry.cpm,
        accuracy: entry.accuracy,
        language: session.language,
        difficulty: session.difficulty,
        inserted_at: entry.inserted_at
      }
    )
    |> Repo.all()
  end

  @doc """
  Gets leaderboard entries for a specific language ordered by CPM descending.
  """
  def get_language_leaderboard(language, limit \\ 10) do
    from(entry in LeaderboardEntry,
      join: session in Session,
      on: entry.session_id == session.id,
      where: session.language == ^language,
      order_by: [desc: entry.cpm, desc: entry.accuracy],
      limit: ^limit,
      select: %{
        player_name: entry.player_name,
        cpm: entry.cpm,
        accuracy: entry.accuracy,
        language: session.language,
        difficulty: session.difficulty,
        inserted_at: entry.inserted_at
      }
    )
    |> Repo.all()
  end

  @doc """
  Gets leaderboard entries for a specific difficulty ordered by CPM descending.
  """
  def get_difficulty_leaderboard(difficulty, limit \\ 10) do
    from(entry in LeaderboardEntry,
      join: session in Session,
      on: entry.session_id == session.id,
      where: session.difficulty == ^difficulty,
      order_by: [desc: entry.cpm, desc: entry.accuracy],
      limit: ^limit,
      select: %{
        player_name: entry.player_name,
        cpm: entry.cpm,
        accuracy: entry.accuracy,
        language: session.language,
        difficulty: session.difficulty,
        inserted_at: entry.inserted_at
      }
    )
    |> Repo.all()
  end

  @doc """
  Gets leaderboard entries for a specific language and difficulty combination.
  """
  def get_language_difficulty_leaderboard(language, difficulty, limit \\ 10) do
    from(entry in LeaderboardEntry,
      join: session in Session,
      on: entry.session_id == session.id,
      where: session.language == ^language and session.difficulty == ^difficulty,
      order_by: [desc: entry.cpm, desc: entry.accuracy],
      limit: ^limit,
      select: %{
        player_name: entry.player_name,
        cpm: entry.cpm,
        accuracy: entry.accuracy,
        language: session.language,
        difficulty: session.difficulty,
        inserted_at: entry.inserted_at
      }
    )
    |> Repo.all()
  end

  @doc """
  Gets all unique languages that have leaderboard entries.
  """
  def get_available_languages do
    from(entry in LeaderboardEntry,
      join: session in Session,
      on: entry.session_id == session.id,
      group_by: session.language,
      select: session.language,
      order_by: session.language
    )
    |> Repo.all()
  end

  @doc """
  Gets all unique difficulties that have leaderboard entries.
  """
  def get_available_difficulties do
    from(entry in LeaderboardEntry,
      join: session in Session,
      on: entry.session_id == session.id,
      group_by: session.difficulty,
      select: session.difficulty,
      order_by: session.difficulty
    )
    |> Repo.all()
  end

  @doc """
  Checks if a leaderboard entry already exists for a session.
  """
  def entry_exists_for_session?(session_id) do
    from(entry in LeaderboardEntry,
      where: entry.session_id == ^session_id,
      select: entry.id
    )
    |> Repo.exists?()
  end
end
