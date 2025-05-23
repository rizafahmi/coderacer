defmodule CoderacerWeb.FinishLiveTest do
  use CoderacerWeb.ConnCase
  import Phoenix.LiveViewTest
  import Coderacer.GameFixtures

  describe "FinishLive" do
    setup do
      session =
        session_fixture(%{
          time_completion: 45,
          streak: 8,
          wrong: 2,
          language: "JavaScript",
          difficulty: :medium
        })

      %{session: session}
    end

    test "renders finish page with session id", %{conn: conn, session: session} do
      {:ok, _view, html} = live(conn, "/finish/#{session.id}")

      assert html =~ "Challenge Complete!"
    end

    test "handles invalid session id gracefully", %{conn: conn} do
      # Test with non-existent session ID
      invalid_id = Ecto.UUID.generate()

      # This should work since the view doesn't actually load the session
      {:ok, _view, html} = live(conn, "/finish/#{invalid_id}")
      assert html =~ "Session not found"
    end
  end
end
