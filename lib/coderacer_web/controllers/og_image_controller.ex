defmodule CoderacerWeb.OgImageController do
  @moduledoc """
  Controller for serving Open Graph images for social media sharing.
  """

  use CoderacerWeb, :controller

  alias Coderacer.Game
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
