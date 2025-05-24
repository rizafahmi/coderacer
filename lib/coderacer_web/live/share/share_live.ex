defmodule CoderacerWeb.ShareLive do
  @moduledoc """
  LiveView for sharing coding challenge results.
  Optimized to encourage visitors to try the game themselves.
  """
  use CoderacerWeb, :live_view

  alias Coderacer.Game

  def mount(%{"id" => id}, session, socket) do
    case Game.get_session(id) do
      nil ->
        {:ok, assign(socket, :error, "Session not found")}

      game_session ->
        # Calculate stats - CPM is the standard metric for typing tests
        cpm =
          if game_session.time_completion > 0,
            do:
              round(
                (game_session.streak + game_session.wrong) * 60 / game_session.time_completion
              ),
            else: 0

        accuracy =
          if game_session.streak + game_session.wrong > 0,
            do: round(game_session.streak / (game_session.streak + game_session.wrong) * 100),
            else: 0

        # Check if this might be the original session owner (simple heuristic)
        is_likely_owner = session["current_session_id"] == id

        socket =
          socket
          |> assign(:session, game_session)
          |> assign(:cpm, cpm)
          |> assign(:accuracy, accuracy)
          |> assign(:is_likely_owner, is_likely_owner)
          |> assign(:page_title, "CodeRacer Results - #{cpm} CPM, #{accuracy}% Accuracy")

        {:ok, socket}
    end
  end
end
