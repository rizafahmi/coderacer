defmodule Coderacer.Repo.Migrations.CreateLeaderboardEntries do
  use Ecto.Migration

  def change do
    create table(:leaderboard_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :player_name, :string, null: false
      add :cpm, :integer, null: false
      add :accuracy, :integer, null: false

      add :session_id, references(:sessions, on_delete: :delete_all, type: :binary_id),
        null: false

      timestamps(type: :utc_datetime)
    end

    create index(:leaderboard_entries, [:session_id])
    create index(:leaderboard_entries, [:cpm])
    create index(:leaderboard_entries, [:accuracy])
  end
end
