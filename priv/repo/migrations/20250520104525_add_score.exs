defmodule Coderacer.Repo.Migrations.AddScore do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      add :streak, :integer, default: 0
      add :wrong, :integer, default: 0
    end
  end
end
