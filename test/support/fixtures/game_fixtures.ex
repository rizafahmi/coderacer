defmodule Coderacer.GameFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Coderacer.Game` context.
  """

  @doc """
  Generate a session.
  """
  def session_fixture(attrs \\ %{}) do
    {:ok, session} =
      attrs
      |> Enum.into(%{
        difficulty: :easy,
        language: "some language",
        time_completion: 42,
        code_challenge: "some code challenge",
        streak: 10,
        wrong: 5
      })
      |> Coderacer.Game.create_session()

    session
  end
end
