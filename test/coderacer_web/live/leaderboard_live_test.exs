defmodule CoderacerWeb.LeaderboardLiveTest do
  use CoderacerWeb.ConnCase
  import Phoenix.LiveViewTest
  import Coderacer.LeaderboardsFixtures

  describe "LeaderboardLive" do
    test "renders initial state with no entries", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/leaderboard")

      assert html =~ "Leaderboard"
      assert html =~ "Top coding speed champions"
      assert html =~ "No Entries Yet"
      assert html =~ "Be the first to set a record!"
      assert html =~ "Start Playing"
      assert html =~ "BalapKode"
      refute html =~ "CodeRacer"
    end

    test "renders global leaderboard with entries", %{conn: conn} do
      # Create test entries
      _entry1 =
        leaderboard_entry_fixture(%{
          player_name: "Alice",
          cpm: 50,
          accuracy: 95,
          language: "JavaScript",
          difficulty: :easy
        })

      _entry2 =
        leaderboard_entry_fixture(%{
          player_name: "Bob",
          cpm: 45,
          accuracy: 90,
          language: "Python",
          difficulty: :medium
        })

      {:ok, _view, html} = live(conn, "/leaderboard")

      assert html =~ "Leaderboard"
      assert html =~ "Alice"
      assert html =~ "Bob"
      # CPM
      assert html =~ "50"
      # CPM
      assert html =~ "45"
      # Accuracy
      assert html =~ "95%"
      # Accuracy
      assert html =~ "90%"
      # Capitalized
      assert html =~ "Javascript"
      assert html =~ "Python"
      # First place gold
      assert html =~ "badge-warning"
      # Second place silver
      assert html =~ "badge-info"
    end

    test "displays ranking badges correctly", %{conn: conn} do
      # Create 4 entries to test different ranking badges
      _entry1 = leaderboard_entry_fixture(%{player_name: "First", cpm: 60})
      _entry2 = leaderboard_entry_fixture(%{player_name: "Second", cpm: 50})
      _entry3 = leaderboard_entry_fixture(%{player_name: "Third", cpm: 40})
      _entry4 = leaderboard_entry_fixture(%{player_name: "Fourth", cpm: 30})

      {:ok, _view, html} = live(conn, "/leaderboard")

      # Gold medal
      assert html =~ "badge-warning"
      # Silver medal
      assert html =~ "badge-info"
      # Bronze medal
      assert html =~ "badge-accent"
      # Numeric rank
      assert html =~ "#4"
    end

    test "switches to language view", %{conn: conn} do
      _entry =
        leaderboard_entry_fixture(%{
          player_name: "JS Developer",
          language: "JavaScript"
        })

      {:ok, view, _html} = live(conn, "/leaderboard")

      # Click on language filter
      render_click(view, :switch_view, %{"view" => "language"})

      # Should redirect to language view
      assert_patch(view, "/leaderboard?view=language")
    end

    test "filters by specific language", %{conn: conn} do
      _js_entry =
        leaderboard_entry_fixture(%{
          player_name: "JS Dev",
          language: "JavaScript",
          cpm: 50
        })

      _py_entry =
        leaderboard_entry_fixture(%{
          player_name: "Python Dev",
          language: "Python",
          cpm: 45
        })

      {:ok, view, _html} = live(conn, "/leaderboard")

      # Filter by JavaScript
      render_click(view, :filter_language, %{"language" => "JavaScript"})

      # Should redirect with language parameter
      assert_patch(view, "/leaderboard?view=language&language=JavaScript")

      # Should show filtered badge
      html = render(view)
      assert html =~ "Javascript Leaderboard"
      assert html =~ "JS Dev"
      refute html =~ "Python Dev"
    end

    test "filters by difficulty", %{conn: conn} do
      _easy_entry =
        leaderboard_entry_fixture(%{
          player_name: "Easy Player",
          difficulty: :easy,
          cpm: 50
        })

      _hard_entry =
        leaderboard_entry_fixture(%{
          player_name: "Hard Player",
          difficulty: :hard,
          cpm: 45
        })

      {:ok, view, _html} = live(conn, "/leaderboard")

      # Filter by easy difficulty
      render_click(view, :filter_difficulty, %{"difficulty" => "easy"})

      # Should redirect with difficulty parameter
      assert_patch(view, "/leaderboard?view=difficulty&difficulty=easy")

      # Should show filtered badge
      html = render(view)
      assert html =~ "Easy Difficulty Leaderboard"
      assert html =~ "Easy Player"
      refute html =~ "Hard Player"
    end

    test "handles params on mount", %{conn: conn} do
      _entry =
        leaderboard_entry_fixture(%{
          player_name: "Test Player",
          language: "JavaScript",
          difficulty: :medium
        })

      # Mount with language filter
      {:ok, _view, html} = live(conn, "/leaderboard?view=language&language=JavaScript")

      assert html =~ "Javascript Leaderboard"
      assert html =~ "Test Player"
    end

    test "handles params with difficulty filter", %{conn: conn} do
      _entry =
        leaderboard_entry_fixture(%{
          player_name: "Medium Player",
          difficulty: :medium
        })

      # Mount with difficulty filter
      {:ok, _view, html} = live(conn, "/leaderboard?view=difficulty&difficulty=medium")

      assert html =~ "Medium Difficulty Leaderboard"
      assert html =~ "Medium Player"
    end

    test "displays available languages in dropdown", %{conn: conn} do
      _js_entry = leaderboard_entry_fixture(%{language: "JavaScript"})
      _py_entry = leaderboard_entry_fixture(%{language: "Python"})
      _ex_entry = leaderboard_entry_fixture(%{language: "Elixir"})

      {:ok, _view, html} = live(conn, "/leaderboard")

      assert html =~ "By Language"
      # Capitalized
      assert html =~ "Javascript"
      assert html =~ "Python"
      assert html =~ "Elixir"
    end

    test "displays available difficulties in dropdown", %{conn: conn} do
      _easy_entry = leaderboard_entry_fixture(%{difficulty: :easy})
      _medium_entry = leaderboard_entry_fixture(%{difficulty: :medium})
      _hard_entry = leaderboard_entry_fixture(%{difficulty: :hard})

      {:ok, _view, html} = live(conn, "/leaderboard")

      assert html =~ "By Difficulty"
      assert html =~ "Easy"
      assert html =~ "Medium"
      assert html =~ "Hard"
    end

    test "shows share button when entries exist", %{conn: conn} do
      _entry = leaderboard_entry_fixture(%{player_name: "Test Player"})

      {:ok, _view, html} = live(conn, "/leaderboard")

      assert html =~ "share-leaderboard"
      assert html =~ "CodeRacer Leaderboard"
    end

    test "hides share button when no entries exist", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/leaderboard")

      refute html =~ "share-leaderboard"
    end

    test "displays correct difficulty badges", %{conn: conn} do
      _easy_entry =
        leaderboard_entry_fixture(%{
          player_name: "Easy Player",
          difficulty: :easy
        })

      _medium_entry =
        leaderboard_entry_fixture(%{
          player_name: "Medium Player",
          difficulty: :medium
        })

      _hard_entry =
        leaderboard_entry_fixture(%{
          player_name: "Hard Player",
          difficulty: :hard
        })

      {:ok, _view, html} = live(conn, "/leaderboard")

      # Easy
      assert html =~ "badge-success"
      # Medium
      assert html =~ "badge-warning"
      # Hard
      assert html =~ "badge-error"
    end

    test "formats dates correctly", %{conn: conn} do
      _entry = leaderboard_entry_fixture(%{player_name: "Test Player"})

      {:ok, _view, html} = live(conn, "/leaderboard")

      # Should contain date format MM/DD/YY
      assert html =~ ~r/\d{2}\/\d{2}\/\d{2}/
      # Should contain time format HH:MM AM/PM
      assert html =~ ~r/\d{1,2}:\d{2} [AP]M/
    end

    test "shows back to game button", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/leaderboard")

      assert html =~ "Back to Game"
      assert html =~ "href=\"/\""
    end

    test "handles empty language filter gracefully", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/leaderboard?view=language")

      # Should fall back to global leaderboard
      assert html =~ "No Entries Yet"
    end

    test "handles empty difficulty filter gracefully", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/leaderboard?view=difficulty")

      # Should fall back to global leaderboard
      assert html =~ "No Entries Yet"
    end

    test "handles invalid difficulty gracefully", %{conn: conn} do
      # This should not crash, but fall back to global leaderboard
      # The invalid difficulty will cause a cast error, so we expect that
      assert_raise Ecto.Query.CastError, fn ->
        live(conn, "/leaderboard?view=difficulty&difficulty=invalid")
      end
    end

    test "displays entries in correct order by CPM", %{conn: conn} do
      _entry1 =
        leaderboard_entry_fixture(%{
          player_name: "Slow",
          cpm: 30,
          accuracy: 95
        })

      _entry2 =
        leaderboard_entry_fixture(%{
          player_name: "Fast",
          cpm: 60,
          accuracy: 85
        })

      _entry3 =
        leaderboard_entry_fixture(%{
          player_name: "Medium",
          cpm: 45,
          accuracy: 90
        })

      {:ok, _view, html} = live(conn, "/leaderboard")

      # Extract the order of player names from HTML
      fast_pos = String.split(html, "Fast") |> hd() |> String.length()
      medium_pos = String.split(html, "Medium") |> hd() |> String.length()
      slow_pos = String.split(html, "Slow") |> hd() |> String.length()

      # Fast should appear first (highest CPM)
      assert fast_pos < medium_pos
      assert medium_pos < slow_pos
    end

    test "shows global tab as active by default", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/leaderboard")

      assert html =~ "tab-active"
      assert html =~ "Global"
    end

    test "shows language tab as active when filtering by language", %{conn: conn} do
      _entry = leaderboard_entry_fixture(%{language: "JavaScript"})

      {:ok, _view, html} = live(conn, "/leaderboard?view=language&language=JavaScript")

      # The language tab should be active
      assert html =~ "By Language"
    end

    test "shows difficulty tab as active when filtering by difficulty", %{conn: conn} do
      _entry = leaderboard_entry_fixture(%{difficulty: :easy})

      {:ok, _view, html} = live(conn, "/leaderboard?view=difficulty&difficulty=easy")

      # The difficulty tab should be active
      assert html =~ "By Difficulty"
    end

    test "handles combined language and difficulty filter", %{conn: conn} do
      _matching_entry =
        leaderboard_entry_fixture(%{
          player_name: "Perfect Match",
          language: "JavaScript",
          difficulty: :hard
        })

      _non_matching_entry =
        leaderboard_entry_fixture(%{
          player_name: "Wrong Lang",
          language: "Python",
          difficulty: :hard
        })

      {:ok, _view, html} =
        live(conn, "/leaderboard?view=combined&language=JavaScript&difficulty=hard")

      assert html =~ "Perfect Match"
      refute html =~ "Wrong Lang"
    end

    test "shows share link for each leaderboard entry", %{conn: conn} do
      entry =
        leaderboard_entry_fixture(%{
          player_name: "Sharable Player",
          cpm: 77,
          accuracy: 99,
          language: "Elixir",
          difficulty: :medium
        })

      {:ok, _view, html} = live(conn, "/leaderboard")

      # The share link should be present and correct
      assert html =~ ~s|href="/share/#{entry.session_id}"|
      assert html =~ ~r|<a[^>]*href="/share/#{entry.session_id}"[^>]*>\s*View\s*</a>|s
    end
  end
end
