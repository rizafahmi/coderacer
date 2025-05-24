defmodule Coderacer.Game.Session do
  @moduledoc """
  This module defines the schema and changeset for a game session, including fields for language, difficulty, and time completion.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Coderacer.Leaderboards.LeaderboardEntry

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sessions" do
    field :language, :string
    field :difficulty, Ecto.Enum, values: [:easy, :medium, :hard]
    field :time_completion, :integer, default: 0
    field :code_challenge, :string, default: ""
    field :streak, :integer, default: 0
    field :wrong, :integer, default: 0

    has_many :leaderboard_entries, LeaderboardEntry

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:language, :difficulty, :time_completion, :code_challenge, :streak, :wrong])
    |> validate_required([:language, :difficulty])
  end
end
