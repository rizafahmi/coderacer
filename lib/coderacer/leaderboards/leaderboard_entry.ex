defmodule Coderacer.Leaderboards.LeaderboardEntry do
  @moduledoc """
  Schema for leaderboard entries containing player names and their performance scores.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Coderacer.Game.Session

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "leaderboard_entries" do
    field :player_name, :string
    field :cpm, :integer
    field :accuracy, :integer

    belongs_to :session, Session

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(leaderboard_entry, attrs) do
    leaderboard_entry
    |> cast(attrs, [:player_name, :cpm, :accuracy, :session_id])
    |> validate_required([:player_name, :cpm, :accuracy, :session_id])
    |> validate_length(:player_name, min: 1, max: 50)
    |> validate_number(:cpm, greater_than_or_equal_to: 0)
    |> validate_number(:accuracy, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> foreign_key_constraint(:session_id)
  end
end
