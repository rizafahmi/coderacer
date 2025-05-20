defmodule Coderacer.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :language, :string
      add :difficulty, :string
      add :time_completion, :integer, default: 0

      timestamps(type: :utc_datetime)
    end
  end
end
