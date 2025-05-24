defmodule CoderacerWeb.OgImageController do
  @moduledoc """
  Controller for serving Open Graph images for social media sharing.
  """

  use CoderacerWeb, :controller

  alias Coderacer.Game
  alias Coderacer.Leaderboards
  alias Coderacer.ImageGenerator

  def show(conn, %{"id" => session_id}) do
    case Game.get_session(session_id) do
      nil ->
        # Return fallback image for missing sessions
        svg_content = ImageGenerator.generate_fallback_svg()

        conn
        |> put_resp_content_type("image/svg+xml")
        |> put_resp_header("cache-control", "public, max-age=86400")
        |> send_resp(200, svg_content)

      session ->
        # Calculate performance metrics
        cpm = calculate_cpm(session)
        accuracy = calculate_accuracy(session)

        # Generate SVG image
        svg_content = ImageGenerator.generate_og_svg(session, cpm, accuracy)

        conn
        |> put_resp_content_type("image/svg+xml")
        |> put_resp_header("cache-control", "public, max-age=86400")
        |> send_resp(200, svg_content)
    end
  end

  def leaderboard(conn, params) do
    view_type = params["view"] || "global"
    language = params["language"]
    difficulty = params["difficulty"]

    # Load leaderboard data
    entries =
      case view_type do
        "global" ->
          Leaderboards.get_global_leaderboard()

        "language" when not is_nil(language) ->
          Leaderboards.get_language_leaderboard(language)

        "difficulty" when not is_nil(difficulty) ->
          difficulty_atom = String.to_existing_atom(difficulty)
          Leaderboards.get_difficulty_leaderboard(difficulty_atom)

        "combined" when not is_nil(language) and not is_nil(difficulty) ->
          difficulty_atom = String.to_existing_atom(difficulty)
          Leaderboards.get_language_difficulty_leaderboard(language, difficulty_atom)

        _ ->
          Leaderboards.get_global_leaderboard()
      end

    # Generate filter info for image title
    filter_info = build_filter_info(view_type, language, difficulty)

    # Generate SVG image
    svg_content =
      if Enum.empty?(entries) do
        ImageGenerator.generate_fallback_svg()
      else
        ImageGenerator.generate_leaderboard_svg(entries, filter_info)
      end

    conn
    |> put_resp_content_type("image/svg+xml")
    |> put_resp_header("cache-control", "public, max-age=3600")
    |> send_resp(200, svg_content)
  end

  defp build_filter_info(view_type, language, difficulty) do
    case view_type do
      "language" when not is_nil(language) ->
        %{language: language}

      "difficulty" when not is_nil(difficulty) ->
        %{difficulty: String.to_existing_atom(difficulty)}

      "combined" when not is_nil(language) and not is_nil(difficulty) ->
        %{language: language, difficulty: String.to_existing_atom(difficulty)}

      _ ->
        %{}
    end
  end

  defp calculate_cpm(session) do
    total_chars = session.streak + session.wrong

    if session.time_completion > 0 do
      round(total_chars * 60 / session.time_completion)
    else
      0
    end
  end

  defp calculate_accuracy(session) do
    total_chars = session.streak + session.wrong

    if total_chars > 0 do
      round(session.streak / total_chars * 100)
    else
      0
    end
  end
end
