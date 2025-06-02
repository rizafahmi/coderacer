defmodule CoderacerWeb.FinishLive do
  use CoderacerWeb, :live_view

  alias Coderacer.Game
  alias Coderacer.Leaderboards
  alias CoderacerWeb.Layouts

  def mount(%{"id" => id}, _session, socket) do
    case Game.get_session(id) do
      nil ->
        {:ok, assign(socket, :error, "Session not found")}

      session ->
        # Calculate stats - CPM is the standard metric for typing tests
        cpm =
          if session.time_completion > 0,
            do: round((session.streak + session.wrong) * 60 / session.time_completion),
            else: 0

        accuracy =
          if session.streak + session.wrong > 0,
            do: round(session.streak / (session.streak + session.wrong) * 100),
            else: 0

        # Check if already submitted to leaderboard
        already_submitted = Leaderboards.entry_exists_for_session?(session.id)

        og_image_url = url(socket, ~p"/images/og-image.png")

        socket =
          socket
          |> assign(:session, session)
          |> assign(:cpm, cpm)
          |> assign(:accuracy, accuracy)
          |> assign(:already_submitted, already_submitted)
          |> assign(:player_name, "")
          |> assign(:submission_status, nil)
          |> assign(:og_image_url, og_image_url)

        {:ok, socket}
    end
  end

  def handle_event("submit_to_leaderboard", %{"player_name" => player_name}, socket) do
    if String.trim(player_name) == "" do
      {:noreply, put_flash(socket, :error, "🔥 Please enter a player name")}
    else
      case Leaderboards.create_leaderboard_entry(%{
             player_name: String.trim(player_name),
             cpm: socket.assigns.cpm,
             accuracy: socket.assigns.accuracy,
             session_id: socket.assigns.session.id
           }) do
        {:ok, _entry} ->
          socket =
            socket
            |> assign(:already_submitted, true)
            |> assign(:submission_status, :success)
            |> put_flash(:info, "🏆 Score submitted to leaderboard!")

          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "🔥Failed to submit score. Please try again.")}
      end
    end
  end
end
