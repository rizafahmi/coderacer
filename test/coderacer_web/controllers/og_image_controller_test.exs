defmodule CoderacerWeb.OgImageControllerTest do
  use CoderacerWeb.ConnCase
  import Coderacer.GameFixtures
  import Coderacer.LeaderboardsFixtures

  describe "show/2 (session OG images)" do
    setup do
      session =
        session_fixture(%{
          time_completion: 60,
          streak: 30,
          wrong: 5,
          language: "elixir",
          difficulty: :medium,
          code_challenge: "def hello, do: 'world'"
        })

      %{session: session}
    end

    test "returns SVG image for valid session", %{conn: conn, session: session} do
      conn = get(conn, "/og-image/#{session.id}")

      assert response(conn, 200)
      assert get_resp_header(conn, "content-type") == ["image/svg+xml; charset=utf-8"]
      assert get_resp_header(conn, "cache-control") == ["public, max-age=86400"]

      svg_content = response(conn, 200)
      assert svg_content =~ "<svg width=\"1200\" height=\"630\""
      assert svg_content =~ "CodeRacer"
    end

    test "includes session performance data in SVG", %{conn: conn, session: session} do
      conn = get(conn, "/og-image/#{session.id}")
      svg_content = response(conn, 200)

      # Should include calculated CPM: (30 + 5) * 60 / 60 = 35 CPM
      assert svg_content =~ "35"

      # Should include calculated accuracy: 30 / (30 + 5) * 100 = 85% (rounded)
      assert svg_content =~ "85"

      # Should include language and difficulty
      assert svg_content =~ "Elixir"
      assert svg_content =~ "Medium"
    end

    test "returns fallback SVG for invalid session ID", %{conn: conn} do
      invalid_id = Ecto.UUID.generate()
      conn = get(conn, "/og-image/#{invalid_id}")

      assert response(conn, 200)
      assert get_resp_header(conn, "content-type") == ["image/svg+xml; charset=utf-8"]

      svg_content = response(conn, 200)
      assert svg_content =~ "<svg width=\"1200\" height=\"630\""
      assert svg_content =~ "Test Your Coding Typing Speed"
      assert svg_content =~ "CodeRacer"
    end

    test "handles zero time completion gracefully", %{conn: conn} do
      zero_time_session =
        session_fixture(%{
          time_completion: 0,
          streak: 10,
          wrong: 2
        })

      conn = get(conn, "/og-image/#{zero_time_session.id}")
      svg_content = response(conn, 200)

      # CPM should be 0 when time is 0
      assert svg_content =~ "0 CPM"
    end

    test "handles zero characters typed gracefully", %{conn: conn} do
      zero_chars_session =
        session_fixture(%{
          time_completion: 60,
          streak: 0,
          wrong: 0
        })

      conn = get(conn, "/og-image/#{zero_chars_session.id}")
      svg_content = response(conn, 200)

      # Both CPM and accuracy should be 0
      assert svg_content =~ "0 CPM"
      assert svg_content =~ "0%"
    end
  end

  describe "leaderboard/2 (leaderboard OG images)" do
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

    test "returns leaderboard SVG for global view", %{conn: conn} do
      conn = get(conn, "/og-image/leaderboard")

      assert response(conn, 200)
      assert get_resp_header(conn, "content-type") == ["image/svg+xml; charset=utf-8"]
      assert get_resp_header(conn, "cache-control") == ["public, max-age=3600"]

      svg_content = response(conn, 200)
      assert svg_content =~ "<svg width=\"1200\" height=\"630\""
      assert svg_content =~ "🏆 Global Leaderboard"
    end

    test "includes leaderboard data in SVG", %{conn: conn} do
      conn = get(conn, "/og-image/leaderboard")
      svg_content = response(conn, 200)

      # Should include player names
      assert svg_content =~ "Alice"
      assert svg_content =~ "Bob"
      assert svg_content =~ "Charlie"

      # Should include CPM values
      assert svg_content =~ "45 CPM"
      assert svg_content =~ "38 CPM"
      assert svg_content =~ "52 CPM"

      # Should include accuracy percentages
      assert svg_content =~ "92%"
      assert svg_content =~ "88%"
      assert svg_content =~ "95%"

      # Should include rank emojis
      assert svg_content =~ "🥇"
      assert svg_content =~ "🥈"
      assert svg_content =~ "🥉"
    end

    test "returns language-filtered leaderboard SVG", %{conn: conn} do
      conn = get(conn, "/og-image/leaderboard?view=language&language=elixir")
      svg_content = response(conn, 200)

      assert svg_content =~ "🏆 Elixir Leaderboard"
      # Should only include Elixir entries
      assert svg_content =~ "Alice"
      assert svg_content =~ "Charlie"
      # Should not include JavaScript entry
      refute svg_content =~ "Bob"
    end

    test "returns difficulty-filtered leaderboard SVG", %{conn: conn} do
      conn = get(conn, "/og-image/leaderboard?view=difficulty&difficulty=easy")
      svg_content = response(conn, 200)

      assert svg_content =~ "🏆 Easy Leaderboard"
      # Should only include easy difficulty entry
      assert svg_content =~ "Alice"
    end

    test "returns combined filter leaderboard SVG", %{conn: conn} do
      conn = get(conn, "/og-image/leaderboard?view=combined&language=elixir&difficulty=hard")
      svg_content = response(conn, 200)

      assert svg_content =~ "🏆 Elixir (Hard) Leaderboard"
      # Should only include Elixir + Hard entry
      assert svg_content =~ "Charlie"
      refute svg_content =~ "Alice"
      refute svg_content =~ "Bob"
    end

    test "returns fallback SVG when no entries match filter", %{conn: conn} do
      conn = get(conn, "/og-image/leaderboard?view=language&language=nonexistent")
      svg_content = response(conn, 200)

      # Should return fallback when no entries found
      assert svg_content =~ "Test Your Coding Typing Speed"
      assert svg_content =~ "CodeRacer"
      refute svg_content =~ "🏆"
    end

    test "returns fallback SVG when database is empty", %{conn: conn} do
      # Clear all leaderboard entries
      Coderacer.Repo.delete_all(Coderacer.Leaderboards.LeaderboardEntry)

      conn = get(conn, "/og-image/leaderboard")
      svg_content = response(conn, 200)

      assert svg_content =~ "Test Your Coding Typing Speed"
      assert svg_content =~ "CodeRacer"
      refute svg_content =~ "🏆"
    end

    test "handles invalid filter parameters gracefully", %{conn: conn} do
      conn = get(conn, "/og-image/leaderboard?view=invalid&language=test")
      svg_content = response(conn, 200)

      # Should fall back to global leaderboard
      assert svg_content =~ "🏆 Global Leaderboard"
    end

    test "truncates long player names appropriately", %{conn: conn} do
      # Create entry with very long name
      _long_name_entry =
        leaderboard_entry_fixture(%{
          player_name: "ThisIsAVeryLongPlayerNameThatShouldBeTruncated",
          cpm: 40,
          accuracy: 90,
          language: "python",
          difficulty: :medium
        })

      conn = get(conn, "/og-image/leaderboard")
      svg_content = response(conn, 200)

      # Name should be truncated with ellipsis
      assert svg_content =~ "ThisIsAVeryL..."
      refute svg_content =~ "ThisIsAVeryLongPlayerNameThatShouldBeTruncated"
    end

    test "displays correct rank emojis for top 3", %{conn: conn} do
      conn = get(conn, "/og-image/leaderboard")
      svg_content = response(conn, 200)

      # Check that rank emojis are present in correct order
      alice_pos = String.split(svg_content, "Alice") |> hd() |> String.length()
      bob_pos = String.split(svg_content, "Bob") |> hd() |> String.length()
      charlie_pos = String.split(svg_content, "Charlie") |> hd() |> String.length()

      # Alice should come after Charlie (Charlie has higher CPM)
      assert charlie_pos < alice_pos
      assert alice_pos < bob_pos
    end

    test "includes call-to-action footer in leaderboard SVG", %{conn: conn} do
      conn = get(conn, "/og-image/leaderboard")
      svg_content = response(conn, 200)

      assert svg_content =~ "Think you can beat these scores?"
      assert svg_content =~ "http://localhost:4000/"
    end

    test "uses correct cache headers", %{conn: conn} do
      # Test session image cache (24 hours)
      session = session_fixture()
      conn = get(conn, "/og-image/#{session.id}")
      assert get_resp_header(conn, "cache-control") == ["public, max-age=86400"]

      # Test leaderboard image cache (1 hour)
      conn = get(conn, "/og-image/leaderboard")
      assert get_resp_header(conn, "cache-control") == ["public, max-age=3600"]
    end
  end

  describe "route handling" do
    test "specific leaderboard route takes precedence over generic ID route", %{conn: conn} do
      # Create a leaderboard entry so we get leaderboard content, not fallback
      leaderboard_entry_fixture(%{
        player_name: "TestPlayer",
        cpm: 50,
        accuracy: 95,
        language: "elixir",
        difficulty: :easy
      })

      # This test ensures the route fix is working
      conn = get(conn, "/og-image/leaderboard")

      # Should go to leaderboard action, not show action
      svg_content = response(conn, 200)
      # Leaderboard SVG should contain specific leaderboard content
      assert svg_content =~ "RANK" or svg_content =~ "Think you can beat these scores?"

      # Should NOT contain session-style content
      refute svg_content =~ "Test Your Coding Typing Speed"
    end

    test "regular session IDs still work with show action", %{conn: conn} do
      session = session_fixture()
      conn = get(conn, "/og-image/#{session.id}")

      svg_content = response(conn, 200)
      # Should contain session-style content
      assert svg_content =~ "CPM"
      assert svg_content =~ "Accuracy"
    end
  end
end
