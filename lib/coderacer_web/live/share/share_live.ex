defmodule CoderacerWeb.ShareLive do
  use CoderacerWeb, :live_view

  @moduledoc """
  LiveView for sharing coding challenge results.
  Optimized to encourage visitors to try the game themselves.
  """

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

        # Create share description
        language = String.capitalize(game_session.language)
        difficulty = game_session.difficulty |> to_string() |> String.capitalize()

        share_description =
          "I scored #{cpm} CPM with #{accuracy}% accuracy in #{language} (#{difficulty}) on CodeRacer! Can you beat my score?"

        # Set up meta tags for social sharing
        og_image_url = url(socket, ~p"/og-image/#{id}")
        share_url = url(socket, ~p"/share/#{id}")

        socket =
          socket
          |> assign(:session, game_session)
          |> assign(:cpm, cpm)
          |> assign(:accuracy, accuracy)
          |> assign(:is_likely_owner, is_likely_owner)
          |> assign(:page_title, "CodeRacer Results - #{cpm} CPM, #{accuracy}% Accuracy")
          |> assign(:share_description, share_description)
          |> assign(:og_image_url, og_image_url)
          |> assign(:share_url, share_url)

        {:ok, socket}
    end
  end
end
