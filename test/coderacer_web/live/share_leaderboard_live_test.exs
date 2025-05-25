defmodule CoderacerWeb.ShareLeaderboardLiveTest do
  use CoderacerWeb.ConnCase
  import Phoenix.LiveViewTest
  import Coderacer.LeaderboardsFixtures

  describe "ShareLeaderboardLive" do
    setup do
      # Create test leaderboard entries
      entry1 =
        leaderboard_entry_fixture(%{
          player_name: "Alice",
          cpm: 45,
          accuracy: 92,
          language: "elixir",
          difficulty: :easy
        })

      entry2 =
        leaderboard_entry_fixture(%{
          player_name: "Bob",
          cpm: 38,
          accuracy: 88,
          language: "javascript",
          difficulty: :medium
        })

      entry3 =
        leaderboard_entry_fixture(%{
          player_name: "Charlie",
          cpm: 52,
          accuracy: 95,
          language: "elixir",
          difficulty: :hard
        })

      %{entries: [entry1, entry2, entry3]}
    end

    test "renders global leaderboard share page", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/share/leaderboard")

      assert html =~ "🏆 Global Leaderboard"
      assert html =~ "Top coding speed champions"
      assert html =~ "Think You Can Beat These Scores?"
      assert html =~ "Start Your Challenge"
    end

    test "assigns correct Open Graph meta data for global leaderboard", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/share/leaderboard")

      # Check meta tags in the HTML
      assert html =~ "Global Leaderboard - CodeRacer"
      assert html =~ "Check out the top coding speed champions on CodeRacer!"
      assert html =~ "/share/leaderboard?view=global"
      assert html =~ "/og-image/leaderboard?view=global"
    end

    test "renders language-filtered leaderboard", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/share/leaderboard?view=language&language=elixir")

      assert html =~ "🏆 Elixir Leaderboard"
      assert html =~ "Top coding speed champions"
    end

    test "assigns correct meta data for language-filtered leaderboard", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/share/leaderboard?view=language&language=elixir")

      # Check meta tags in the HTML
      assert html =~ "Elixir Leaderboard - CodeRacer"
      assert html =~ "Check out the top Elixir coding speed champions"
      assert html =~ "/share/leaderboard?view=language&amp;language=elixir"
      assert html =~ "/og-image/leaderboard?view=language&amp;language=elixir"
    end

    test "renders difficulty-filtered leaderboard", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/share/leaderboard?view=difficulty&difficulty=hard")

      assert html =~ "🏆 Hard Difficulty Leaderboard"
      assert html =~ "Top coding speed champions"
    end

    test "assigns correct meta data for difficulty-filtered leaderboard", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/share/leaderboard?view=difficulty&difficulty=hard")

      # Check meta tags in the HTML
      assert html =~ "Hard Difficulty Leaderboard - CodeRacer"
      assert html =~ "Check out the top Hard difficulty coding speed champions"
      assert html =~ "/share/leaderboard?view=difficulty&amp;difficulty=hard"
      assert html =~ "/og-image/leaderboard?view=difficulty&amp;difficulty=hard"
    end

    test "renders combined language-difficulty filtered leaderboard", %{conn: conn} do
      {:ok, _view, html} =
        live(conn, "/share/leaderboard?view=combined&language=elixir&difficulty=easy")

      assert html =~ "🏆 Elixir (Easy) Leaderboard"
      assert html =~ "Top coding speed champions"
    end

    test "assigns correct meta data for combined filter", %{conn: conn} do
      {:ok, _view, html} =
        live(conn, "/share/leaderboard?view=combined&language=elixir&difficulty=easy")

      # Check meta tags in the HTML
      assert html =~ "Elixir (Easy) Leaderboard - CodeRacer"
      assert html =~ "Check out the top Elixir (Easy) coding speed champions"
      assert html =~ "/share/leaderboard?view=combined&amp;language=elixir&amp;difficulty=easy"
      assert html =~ "/og-image/leaderboard?view=combined&amp;language=elixir&amp;difficulty=easy"
    end

    test "displays leaderboard entries with correct data", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/share/leaderboard")

      # Should display player names, CPM, accuracy, language, difficulty
      assert html =~ "Alice"
      assert html =~ "Bob"
      assert html =~ "Charlie"
      # CPM
      assert html =~ "45"
      # Accuracy
      assert html =~ "92%"
      assert html =~ "Elixir"
      assert html =~ "Javascript"
    end

    test "includes share button with correct props", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/share/leaderboard")

      assert html =~ "share-leaderboard"
      assert html =~ "CodeRacer Leaderboard 🏆"
      assert html =~ "Check out this CodeRacer leaderboard! 🏆"
      assert html =~ "Share"
    end

    test "shows empty state when no leaderboard entries", %{conn: conn} do
      # Clear all leaderboard entries
      Coderacer.Repo.delete_all(Coderacer.Leaderboards.LeaderboardEntry)

      {:ok, _view, html} = live(conn, "/share/leaderboard")

      assert html =~ "No Entries Yet"
      assert html =~ "Be the first to set a record!"
      # Should not show share button when empty
      refute html =~ "share-leaderboard"
    end

    test "includes visitor call-to-action section", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/share/leaderboard")

      assert html =~ "Think You Can Beat These Scores?"
      assert html =~ "Join the competition and test your coding typing skills"
      assert html =~ "Start Your Challenge"
      assert html =~ "20+ Programming Languages • All Skill Levels • Free Forever"
    end

    test "handles invalid filter parameters gracefully", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/share/leaderboard?view=invalid&language=nonexistent")

      # Should fall back to global leaderboard
      assert html =~ "🏆 Global Leaderboard"
    end

    test "generates correct share URLs for different filters", %{conn: conn} do
      # Test global
      {:ok, _view, html} = live(conn, "/share/leaderboard")
      assert html =~ "view=global"

      # Test language filter
      {:ok, _view, html} = live(conn, "/share/leaderboard?view=language&language=rust")
      assert html =~ "view=language"
      assert html =~ "language=rust"

      # Test difficulty filter
      {:ok, _view, html} = live(conn, "/share/leaderboard?view=difficulty&difficulty=medium")
      assert html =~ "view=difficulty"
      assert html =~ "difficulty=medium"
    end

    test "generates correct OG image URLs for different filters", %{conn: conn} do
      # Test global
      {:ok, _view, html} = live(conn, "/share/leaderboard")
      assert html =~ "/og-image/leaderboard"
      assert html =~ "view=global"

      # Test language filter
      {:ok, _view, html} = live(conn, "/share/leaderboard?view=language&language=python")
      assert html =~ "/og-image/leaderboard"
      assert html =~ "view=language"
      assert html =~ "language=python"
    end

    test "displays rank badges correctly", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/share/leaderboard")

      # Check for rank display (emojis are shown in the template)
      assert html =~ "badge"
      assert html =~ "text-center"
    end

    test "formats difficulty badges correctly", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/share/leaderboard")

      assert html =~ "Easy"
      assert html =~ "Medium"
      assert html =~ "Hard"
    end

    test "shows correct page structure", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/share/leaderboard")

      # Header section
      assert html =~ "text-center mb-8"
      assert html =~ "🏆 Global Leaderboard"

      # Table structure
      assert html =~ "table table-zebra"
      assert html =~ "Rank"
      assert html =~ "Player"
      assert html =~ "CPM"
      assert html =~ "Accuracy"
      assert html =~ "Language"
      assert html =~ "Difficulty"
      assert html =~ "Date"

      # Call to action
      assert html =~ "bg-gradient-to-r"
      assert html =~ "Start Your Challenge"
    end
  end
end
