defmodule Coderacer.Repo.Migrations.AddCodeChallenge do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      add :code_challenge, :string
    end
  end
end
