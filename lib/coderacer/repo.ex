defmodule Coderacer.Repo do
  use Ecto.Repo,
    otp_app: :coderacer,
    adapter: Ecto.Adapters.SQLite3
end
