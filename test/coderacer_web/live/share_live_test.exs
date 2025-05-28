defmodule CoderacerWeb.ShareLiveTest do
  use CoderacerWeb.ConnCase
  import Phoenix.LiveViewTest
  import Coderacer.GameFixtures

  describe "ShareLive" do
    setup do
      session =
        session_fixture(%{
          time_completion: 45,
          streak: 8,
          wrong: 2,
          language: "javascript",
          difficulty: :medium,
          code_challenge: "const hello = 'world';"
        })

      %{session: session}
    end

    test "renders share page with session results", %{conn: conn, session: session} do
      {:ok, _view, html} = live(conn, "/share/#{session.id}")

      assert html =~ "CodeRacer Results"
      assert html =~ "Check out this coding challenge performance!"
    end

    test "displays performance statistics correctly", %{conn: conn, session: session} do
      {:ok, _view, html} = live(conn, "/share/#{session.id}")

      # Should show CPM calculation: (8 + 2) * 60 / 45 = 13 CPM (rounded)
      assert html =~ "13"
      assert html =~ "Characters/Min"

      # Should show accuracy: 8 / (8 + 2) * 100 = 80%
      assert html =~ "80%"
      assert html =~ "Accuracy"

      # Should show time completion
      assert html =~ "45s"
      assert html =~ "Time Taken"

      # Should show wrong count
      assert html =~ "2"
      assert html =~ "Errors"
    end

    test "displays language and difficulty correctly", %{conn: conn, session: session} do
      {:ok, _view, html} = live(conn, "/share/#{session.id}")

      assert html =~ "Javascript"
      assert html =~ "Medium"
    end

    test "includes visitor CTA section", %{conn: conn, session: session} do
      {:ok, _view, html} = live(conn, "/share/#{session.id}")

      assert html =~ "Think You Can Do Better?"
      assert html =~ "Test your coding typing speed and accuracy!"
      assert html =~ "Start Your Challenge"
      assert html =~ "Free • No signup required • Instant results"
    end

    test "includes share functionality", %{conn: conn, session: session} do
      {:ok, _view, html} = live(conn, "/share/#{session.id}")

      assert html =~ "Performance Analysis"
      assert html =~ "Share"

      assert html =~
               "sharePerformance(cpm, accuracy, time_completion, wrong, language, difficulty)"
    end

    test "includes navigation buttons", %{conn: conn, session: session} do
      {:ok, _view, html} = live(conn, "/share/#{session.id}")

      assert html =~ "View Leaderboard"
      # Should NOT include "View Full Results" button as we removed it
      refute html =~ "View Full Results"
    end

    test "handles invalid session id gracefully", %{conn: conn} do
      invalid_id = Ecto.UUID.generate()
      {:ok, _view, html} = live(conn, "/share/#{invalid_id}")

      assert html =~ "Session not found"
    end

    test "includes motivational quote", %{conn: conn, session: session} do
      {:ok, _view, html} = live(conn, "/share/#{session.id}")

      assert html =~ "The only way to learn a new programming language"
      assert html =~ "Dennis Ritchie"
    end

    test "performance insights show correct feedback", %{conn: conn, session: session} do
      {:ok, _view, html} = live(conn, "/share/#{session.id}")

      # With 80% accuracy (< 95%), should show accuracy improvement tip
      assert html =~ "Focus on accuracy over speed"

      # With 13 CPM (< 200), should show speed improvement tip
      assert html =~ "Practice regularly to improve"

      # With 2 errors (≤ 3), should show positive feedback
      assert html =~ "Very few errors - keep up the good work!"
    end

    test "calculates CPM and accuracy correctly for edge cases", %{conn: conn} do
      # Test zero time completion
      session_zero_time = session_fixture(%{time_completion: 0, streak: 10, wrong: 5})
      {:ok, _view, html} = live(conn, "/share/#{session_zero_time.id}")
      # CPM should be 0
      assert html =~ "0"

      # Test zero characters typed
      session_zero_chars = session_fixture(%{time_completion: 60, streak: 0, wrong: 0})
      {:ok, _view, html} = live(conn, "/share/#{session_zero_chars.id}")
      # Both CPM and accuracy should be 0
      assert html =~ "0"
    end
  end
end
