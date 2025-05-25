defmodule Coderacer.LeaderboardsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Coderacer.Leaderboards` context.
  """

  import Coderacer.GameFixtures

  @doc """
  Generate a leaderboard entry.
  """
  def leaderboard_entry_fixture(attrs \\ %{}) do
    # Extract session-related attributes
    {session_attrs, entry_attrs} = Map.split(attrs, [:language, :difficulty])

    # Create a session with the specified language/difficulty
    session = session_fixture(session_attrs)

    {:ok, leaderboard_entry} =
      entry_attrs
      |> Enum.into(%{
        player_name: "Test Player",
        cpm: 42,
        accuracy: 85,
        session_id: session.id
      })
      |> Coderacer.Leaderboards.create_leaderboard_entry()

    leaderboard_entry
  end
end
