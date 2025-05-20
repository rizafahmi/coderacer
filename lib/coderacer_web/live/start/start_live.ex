defmodule CoderacerWeb.StartLive do
  use CoderacerWeb, :live_view

  alias Coderacer.Game

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("submit_choice", %{"language" => language, "difficulty" => difficulty}, socket) do
    code = Coderacer.AI.generate(language, 25, difficulty)

    case Game.create_session(%{
           language: language,
           difficulty: String.to_atom(difficulty),
           code_challenge: code
         }) do
      {:ok, session} ->
        socket =
          socket
          |> push_navigate(to: ~p"/game/#{session.id}")

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, "Error creating session", :error)}
    end
  end
end
