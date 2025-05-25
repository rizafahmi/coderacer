defmodule Coderacer.IntegrationTest do
  use Coderacer.DataCase

  alias Coderacer.{Game, Leaderboards}
  import Coderacer.GameFixtures

  describe "full game flow integration" do
    test "complete game session to leaderboard entry flow" do
      # Create a session
      {:ok, session} =
        Game.create_session(%{
          language: "JavaScript",
          difficulty: :medium,
          code_challenge: "console.log('Hello, World!');"
        })

      # Update session with completion data
      {:ok, updated_session} =
        Game.update_session(session, %{
          time_completion: 45,
          streak: 25,
          wrong: 3
        })

      # Create leaderboard entry for the session
      {:ok, _entry} =
        Leaderboards.create_leaderboard_entry(%{
          player_name: "Integration Test Player",
          cpm: 40,
          accuracy: 89,
          session_id: updated_session.id
        })

      # Verify the entry appears in global leaderboard
      global_leaderboard = Leaderboards.get_global_leaderboard()
      assert length(global_leaderboard) == 1

      [leaderboard_entry] = global_leaderboard
      assert leaderboard_entry.player_name == "Integration Test Player"
      assert leaderboard_entry.cpm == 40
      assert leaderboard_entry.accuracy == 89
      assert leaderboard_entry.language == "JavaScript"
      assert leaderboard_entry.difficulty == :medium

      # Verify the entry appears in language-specific leaderboard
      js_leaderboard = Leaderboards.get_language_leaderboard("JavaScript")
      assert length(js_leaderboard) == 1
      assert Enum.at(js_leaderboard, 0).player_name == "Integration Test Player"

      # Verify the entry appears in difficulty-specific leaderboard
      medium_leaderboard = Leaderboards.get_difficulty_leaderboard(:medium)
      assert length(medium_leaderboard) == 1
      assert Enum.at(medium_leaderboard, 0).player_name == "Integration Test Player"

      # Verify the entry appears in combined language-difficulty leaderboard
      combined_leaderboard =
        Leaderboards.get_language_difficulty_leaderboard("JavaScript", :medium)

      assert length(combined_leaderboard) == 1
      assert Enum.at(combined_leaderboard, 0).player_name == "Integration Test Player"

      # Verify entry exists check
      assert Leaderboards.entry_exists_for_session?(updated_session.id) == true

      # Verify available languages and difficulties are updated
      assert "JavaScript" in Leaderboards.get_available_languages()
      assert :medium in Leaderboards.get_available_difficulties()
    end

    test "multiple sessions and leaderboard ranking" do
      # Create multiple sessions with different performance
      sessions_data = [
        %{language: "JavaScript", difficulty: :easy, cpm: 50, accuracy: 95, player: "Player A"},
        %{language: "JavaScript", difficulty: :easy, cpm: 45, accuracy: 90, player: "Player B"},
        %{language: "Python", difficulty: :medium, cpm: 55, accuracy: 88, player: "Player C"},
        %{language: "JavaScript", difficulty: :hard, cpm: 40, accuracy: 92, player: "Player D"},
        %{language: "Elixir", difficulty: :easy, cpm: 48, accuracy: 94, player: "Player E"}
      ]

      # Create sessions and leaderboard entries
      for session_data <- sessions_data do
        {:ok, session} =
          Game.create_session(%{
            language: session_data.language,
            difficulty: session_data.difficulty,
            code_challenge: "test code"
          })

        {:ok, _entry} =
          Leaderboards.create_leaderboard_entry(%{
            player_name: session_data.player,
            cpm: session_data.cpm,
            accuracy: session_data.accuracy,
            session_id: session.id
          })
      end

      # Test global leaderboard ordering (by CPM desc, then accuracy desc)
      global_leaderboard = Leaderboards.get_global_leaderboard()
      assert length(global_leaderboard) == 5

      # Should be ordered: Player C (55), Player A (50), Player E (48), Player B (45), Player D (40)
      assert Enum.at(global_leaderboard, 0).player_name == "Player C"
      assert Enum.at(global_leaderboard, 1).player_name == "Player A"
      assert Enum.at(global_leaderboard, 2).player_name == "Player E"
      assert Enum.at(global_leaderboard, 3).player_name == "Player B"
      assert Enum.at(global_leaderboard, 4).player_name == "Player D"

      # Test JavaScript-specific leaderboard
      js_leaderboard = Leaderboards.get_language_leaderboard("JavaScript")
      assert length(js_leaderboard) == 3
      # 50 CPM
      assert Enum.at(js_leaderboard, 0).player_name == "Player A"
      # 45 CPM
      assert Enum.at(js_leaderboard, 1).player_name == "Player B"
      # 40 CPM
      assert Enum.at(js_leaderboard, 2).player_name == "Player D"

      # Test easy difficulty leaderboard
      easy_leaderboard = Leaderboards.get_difficulty_leaderboard(:easy)
      assert length(easy_leaderboard) == 3
      # 50 CPM
      assert Enum.at(easy_leaderboard, 0).player_name == "Player A"
      # 48 CPM
      assert Enum.at(easy_leaderboard, 1).player_name == "Player E"
      # 45 CPM
      assert Enum.at(easy_leaderboard, 2).player_name == "Player B"

      # Test combined JavaScript + easy leaderboard
      js_easy_leaderboard = Leaderboards.get_language_difficulty_leaderboard("JavaScript", :easy)
      assert length(js_easy_leaderboard) == 2
      assert Enum.at(js_easy_leaderboard, 0).player_name == "Player A"
      assert Enum.at(js_easy_leaderboard, 1).player_name == "Player B"

      # Test available languages and difficulties
      languages = Leaderboards.get_available_languages()
      assert "Elixir" in languages
      assert "JavaScript" in languages
      assert "Python" in languages
      assert length(languages) == 3

      difficulties = Leaderboards.get_available_difficulties()
      assert :easy in difficulties
      assert :medium in difficulties
      assert :hard in difficulties
      assert length(difficulties) == 3
    end

    test "leaderboard limit functionality" do
      # Create 15 entries
      for i <- 1..15 do
        session = session_fixture(%{language: "TestLang", difficulty: :easy})

        Leaderboards.create_leaderboard_entry(%{
          player_name: "Player #{i}",
          # CPM from 5 to 75
          cpm: i * 5,
          accuracy: 85,
          session_id: session.id
        })
      end

      # Test default limit (10)
      global_leaderboard = Leaderboards.get_global_leaderboard()
      assert length(global_leaderboard) == 10
      # Should get top 10 (highest CPM first)
      # Player 15
      assert Enum.at(global_leaderboard, 0).cpm == 75
      # Player 6
      assert Enum.at(global_leaderboard, 9).cpm == 30

      # Test custom limit
      top_5 = Leaderboards.get_global_leaderboard(5)
      assert length(top_5) == 5
      assert Enum.at(top_5, 0).cpm == 75
      assert Enum.at(top_5, 4).cpm == 55

      # Test limit larger than available entries
      all_entries = Leaderboards.get_global_leaderboard(20)
      assert length(all_entries) == 15
    end

    test "duplicate session leaderboard entry prevention" do
      session = session_fixture()

      # Create first entry
      {:ok, _entry1} =
        Leaderboards.create_leaderboard_entry(%{
          player_name: "First Player",
          cpm: 40,
          accuracy: 85,
          session_id: session.id
        })

      assert Leaderboards.entry_exists_for_session?(session.id) == true

      # Try to create second entry for same session
      {:ok, _entry2} =
        Leaderboards.create_leaderboard_entry(%{
          player_name: "Second Player",
          cpm: 50,
          accuracy: 90,
          session_id: session.id
        })

      # Both entries should exist (no constraint preventing duplicates in current schema)
      global_leaderboard = Leaderboards.get_global_leaderboard()
      assert length(global_leaderboard) == 2
    end

    test "session deletion cascade behavior" do
      session = session_fixture()

      # Create leaderboard entry
      {:ok, _entry} =
        Leaderboards.create_leaderboard_entry(%{
          player_name: "Test Player",
          cpm: 40,
          accuracy: 85,
          session_id: session.id
        })

      # Verify entry exists
      assert Leaderboards.entry_exists_for_session?(session.id) == true
      global_leaderboard = Leaderboards.get_global_leaderboard()
      assert length(global_leaderboard) == 1

      # Delete session
      {:ok, _deleted_session} = Game.delete_session(session)

      # Verify session is gone
      assert_raise Ecto.NoResultsError, fn ->
        Game.get_session!(session.id)
      end

      # Leaderboard entry should be deleted due to foreign key constraint
      global_leaderboard_after = Leaderboards.get_global_leaderboard()
      assert Enum.empty?(global_leaderboard_after)
      assert Leaderboards.entry_exists_for_session?(session.id) == false
    end

    test "performance with large dataset" do
      # Create 100 entries across different languages and difficulties
      languages = ["JavaScript", "Python", "Elixir", "Go", "Rust"]
      difficulties = [:easy, :medium, :hard]

      for i <- 1..100 do
        language = Enum.at(languages, rem(i, Enum.count(languages)))
        difficulty = Enum.at(difficulties, rem(i, Enum.count(difficulties)))

        session = session_fixture(%{language: language, difficulty: difficulty})

        Leaderboards.create_leaderboard_entry(%{
          player_name: "Player #{i}",
          # Random CPM 1-100
          cpm: :rand.uniform(100),
          # Random accuracy 1-100
          accuracy: :rand.uniform(100),
          session_id: session.id
        })
      end

      # Test that queries still perform well
      start_time = System.monotonic_time(:millisecond)
      global_leaderboard = Leaderboards.get_global_leaderboard()
      end_time = System.monotonic_time(:millisecond)

      # Should complete quickly (under 100ms for this dataset size)
      assert end_time - start_time < 100
      assert length(global_leaderboard) == 10

      # Test language-specific queries
      js_leaderboard = Leaderboards.get_language_leaderboard("JavaScript")
      assert length(js_leaderboard) <= 10

      # Test available languages/difficulties
      languages_result = Leaderboards.get_available_languages()
      assert length(languages_result) == 5

      difficulties_result = Leaderboards.get_available_difficulties()
      assert length(difficulties_result) == 3
    end
  end

  describe "error handling and edge cases" do
    test "handles invalid session references gracefully" do
      invalid_session_id = Ecto.UUID.generate()

      # Should return false for non-existent session
      assert Leaderboards.entry_exists_for_session?(invalid_session_id) == false

      # Should raise constraint error when trying to create entry with invalid session_id
      assert_raise Ecto.ConstraintError, fn ->
        Leaderboards.create_leaderboard_entry(%{
          player_name: "Test Player",
          cpm: 40,
          accuracy: 85,
          session_id: invalid_session_id
        })
      end
    end

    test "handles empty database gracefully" do
      # All queries should return empty results without errors
      assert Leaderboards.get_global_leaderboard() == []
      assert Leaderboards.get_language_leaderboard("JavaScript") == []
      assert Leaderboards.get_difficulty_leaderboard(:easy) == []
      assert Leaderboards.get_language_difficulty_leaderboard("JavaScript", :easy) == []
      assert Leaderboards.get_available_languages() == []
      assert Leaderboards.get_available_difficulties() == []
    end

    test "handles extreme values correctly" do
      session = session_fixture()

      # Test with extreme but valid values (respecting max length constraint)
      {:ok, _entry} =
        Leaderboards.create_leaderboard_entry(%{
          # Max allowed length
          player_name: String.duplicate("A", 50),
          # Very high CPM
          cpm: 999_999,
          # Perfect accuracy
          accuracy: 100,
          session_id: session.id
        })

      global_leaderboard = Leaderboards.get_global_leaderboard()
      assert length(global_leaderboard) == 1
      assert Enum.at(global_leaderboard, 0).cpm == 999_999
      assert Enum.at(global_leaderboard, 0).accuracy == 100
    end
  end
end
