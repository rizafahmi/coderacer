defmodule Coderacer.LeaderboardsTest do
  use Coderacer.DataCase

  alias Coderacer.Leaderboards
  alias Coderacer.Leaderboards.LeaderboardEntry

  import Coderacer.GameFixtures
  import Coderacer.LeaderboardsFixtures

  describe "create_leaderboard_entry/1" do
    test "creates a leaderboard entry with valid data" do
      session = session_fixture()

      valid_attrs = %{
        player_name: "Test Player",
        cpm: 45,
        accuracy: 92,
        session_id: session.id
      }

      assert {:ok, %LeaderboardEntry{} = entry} =
               Leaderboards.create_leaderboard_entry(valid_attrs)

      assert entry.player_name == "Test Player"
      assert entry.cpm == 45
      assert entry.accuracy == 92
      assert entry.session_id == session.id
    end

    test "returns error changeset with invalid data" do
      invalid_attrs = %{player_name: nil, cpm: nil, accuracy: nil, session_id: nil}

      assert {:error, %Ecto.Changeset{}} = Leaderboards.create_leaderboard_entry(invalid_attrs)
    end

    test "requires player_name" do
      session = session_fixture()

      attrs = %{
        player_name: "",
        cpm: 45,
        accuracy: 92,
        session_id: session.id
      }

      assert {:error, %Ecto.Changeset{}} = Leaderboards.create_leaderboard_entry(attrs)
    end

    test "requires valid session_id" do
      invalid_session_id = Ecto.UUID.generate()

      attrs = %{
        player_name: "Test Player",
        cpm: 45,
        accuracy: 92,
        session_id: invalid_session_id
      }

      # This will raise a constraint error, not return an error changeset
      assert_raise Ecto.ConstraintError, fn ->
        Leaderboards.create_leaderboard_entry(attrs)
      end
    end

    test "validates cpm is non-negative" do
      session = session_fixture()

      attrs = %{
        player_name: "Test Player",
        cpm: -5,
        accuracy: 92,
        session_id: session.id
      }

      assert {:error, %Ecto.Changeset{}} = Leaderboards.create_leaderboard_entry(attrs)
    end

    test "validates accuracy is between 0 and 100" do
      session = session_fixture()

      # Test accuracy > 100
      attrs = %{
        player_name: "Test Player",
        cpm: 45,
        accuracy: 105,
        session_id: session.id
      }

      assert {:error, %Ecto.Changeset{}} = Leaderboards.create_leaderboard_entry(attrs)

      # Test negative accuracy
      attrs = %{
        player_name: "Test Player",
        cpm: 45,
        accuracy: -5,
        session_id: session.id
      }

      assert {:error, %Ecto.Changeset{}} = Leaderboards.create_leaderboard_entry(attrs)
    end
  end

  describe "get_global_leaderboard/1" do
    test "returns empty list when no entries exist" do
      assert Leaderboards.get_global_leaderboard() == []
    end

    test "returns entries ordered by CPM descending" do
      # Create entries with different CPM values
      _entry1 = leaderboard_entry_fixture(%{cpm: 30, accuracy: 85})
      _entry2 = leaderboard_entry_fixture(%{cpm: 50, accuracy: 90})
      _entry3 = leaderboard_entry_fixture(%{cpm: 40, accuracy: 88})

      results = Leaderboards.get_global_leaderboard()

      assert length(results) == 3
      assert Enum.at(results, 0).cpm == 50
      assert Enum.at(results, 1).cpm == 40
      assert Enum.at(results, 2).cpm == 30
    end

    test "orders by accuracy when CPM is equal" do
      # Create entries with same CPM but different accuracy
      _entry1 = leaderboard_entry_fixture(%{cpm: 45, accuracy: 85})
      _entry2 = leaderboard_entry_fixture(%{cpm: 45, accuracy: 95})
      _entry3 = leaderboard_entry_fixture(%{cpm: 45, accuracy: 90})

      results = Leaderboards.get_global_leaderboard()

      assert length(results) == 3
      assert Enum.at(results, 0).accuracy == 95
      assert Enum.at(results, 1).accuracy == 90
      assert Enum.at(results, 2).accuracy == 85
    end

    test "respects limit parameter" do
      # Create 5 entries
      for i <- 1..5 do
        leaderboard_entry_fixture(%{cpm: i * 10, accuracy: 85})
      end

      results = Leaderboards.get_global_leaderboard(3)
      assert length(results) == 3
    end

    test "includes session data in results" do
      entry =
        leaderboard_entry_fixture(%{
          language: "JavaScript",
          difficulty: :medium,
          cpm: 45,
          accuracy: 90
        })

      [result] = Leaderboards.get_global_leaderboard()

      assert result.player_name == entry.player_name
      assert result.cpm == entry.cpm
      assert result.accuracy == entry.accuracy
      assert result.language == "JavaScript"
      assert result.difficulty == :medium
      assert result.inserted_at
      assert result.session_id == entry.session_id
    end
  end

  describe "get_language_leaderboard/2" do
    test "returns entries for specific language only" do
      # Create entries for different languages
      js_entry = leaderboard_entry_fixture(%{language: "JavaScript", cpm: 45})
      py_entry = leaderboard_entry_fixture(%{language: "Python", cpm: 50})
      _elixir_entry = leaderboard_entry_fixture(%{language: "Elixir", cpm: 40})

      js_results = Leaderboards.get_language_leaderboard("JavaScript")
      py_results = Leaderboards.get_language_leaderboard("Python")

      assert length(js_results) == 1
      assert length(py_results) == 1
      assert Enum.at(js_results, 0).language == "JavaScript"
      assert Enum.at(py_results, 0).language == "Python"
      assert Enum.at(js_results, 0).session_id == js_entry.session_id
      assert Enum.at(py_results, 0).session_id == py_entry.session_id
    end

    test "returns empty list for non-existent language" do
      leaderboard_entry_fixture(%{language: "JavaScript"})

      results = Leaderboards.get_language_leaderboard("NonExistent")
      assert results == []
    end

    test "orders by CPM descending within language" do
      # Create multiple entries for same language
      leaderboard_entry_fixture(%{language: "JavaScript", cpm: 30})
      leaderboard_entry_fixture(%{language: "JavaScript", cpm: 50})
      leaderboard_entry_fixture(%{language: "JavaScript", cpm: 40})

      results = Leaderboards.get_language_leaderboard("JavaScript")

      assert length(results) == 3
      assert Enum.at(results, 0).cpm == 50
      assert Enum.at(results, 1).cpm == 40
      assert Enum.at(results, 2).cpm == 30
    end
  end

  describe "get_difficulty_leaderboard/2" do
    test "returns entries for specific difficulty only" do
      # Create entries for different difficulties
      easy_entry = leaderboard_entry_fixture(%{difficulty: :easy, cpm: 45})
      medium_entry = leaderboard_entry_fixture(%{difficulty: :medium, cpm: 50})
      _hard_entry = leaderboard_entry_fixture(%{difficulty: :hard, cpm: 40})

      easy_results = Leaderboards.get_difficulty_leaderboard(:easy)
      medium_results = Leaderboards.get_difficulty_leaderboard(:medium)

      assert length(easy_results) == 1
      assert length(medium_results) == 1
      assert Enum.at(easy_results, 0).difficulty == :easy
      assert Enum.at(medium_results, 0).difficulty == :medium
      assert Enum.at(easy_results, 0).session_id == easy_entry.session_id
      assert Enum.at(medium_results, 0).session_id == medium_entry.session_id
    end

    test "raises error for invalid difficulty" do
      leaderboard_entry_fixture(%{difficulty: :easy})

      # This should raise an error because :nonexistent is not a valid difficulty
      assert_raise Ecto.Query.CastError, fn ->
        Leaderboards.get_difficulty_leaderboard(:nonexistent)
      end
    end

    test "orders by CPM descending within difficulty" do
      # Create multiple entries for same difficulty
      leaderboard_entry_fixture(%{difficulty: :medium, cpm: 30})
      leaderboard_entry_fixture(%{difficulty: :medium, cpm: 50})
      leaderboard_entry_fixture(%{difficulty: :medium, cpm: 40})

      results = Leaderboards.get_difficulty_leaderboard(:medium)

      assert length(results) == 3
      assert Enum.at(results, 0).cpm == 50
      assert Enum.at(results, 1).cpm == 40
      assert Enum.at(results, 2).cpm == 30
    end
  end

  describe "get_language_difficulty_leaderboard/3" do
    test "returns entries for specific language and difficulty combination" do
      # Create entries with different combinations
      js_easy_entry =
        leaderboard_entry_fixture(%{language: "JavaScript", difficulty: :easy, cpm: 45})

      _js_medium_entry =
        leaderboard_entry_fixture(%{language: "JavaScript", difficulty: :medium, cpm: 50})

      _py_easy_entry =
        leaderboard_entry_fixture(%{language: "Python", difficulty: :easy, cpm: 40})

      results = Leaderboards.get_language_difficulty_leaderboard("JavaScript", :easy)

      assert length(results) == 1
      assert Enum.at(results, 0).language == "JavaScript"
      assert Enum.at(results, 0).difficulty == :easy
      assert Enum.at(results, 0).cpm == 45
      assert Enum.at(results, 0).session_id == js_easy_entry.session_id
    end

    test "returns empty list for non-matching combination" do
      leaderboard_entry_fixture(%{language: "JavaScript", difficulty: :easy})

      results = Leaderboards.get_language_difficulty_leaderboard("Python", :hard)
      assert results == []
    end

    test "orders by CPM descending within language-difficulty combination" do
      # Create multiple entries for same combination
      leaderboard_entry_fixture(%{language: "JavaScript", difficulty: :medium, cpm: 30})
      leaderboard_entry_fixture(%{language: "JavaScript", difficulty: :medium, cpm: 50})
      leaderboard_entry_fixture(%{language: "JavaScript", difficulty: :medium, cpm: 40})

      results = Leaderboards.get_language_difficulty_leaderboard("JavaScript", :medium)

      assert length(results) == 3
      assert Enum.at(results, 0).cpm == 50
      assert Enum.at(results, 1).cpm == 40
      assert Enum.at(results, 2).cpm == 30
    end
  end

  describe "get_available_languages/0" do
    test "returns empty list when no entries exist" do
      assert Leaderboards.get_available_languages() == []
    end

    test "returns unique languages from leaderboard entries" do
      leaderboard_entry_fixture(%{language: "JavaScript"})
      leaderboard_entry_fixture(%{language: "Python"})
      # Duplicate
      leaderboard_entry_fixture(%{language: "JavaScript"})
      leaderboard_entry_fixture(%{language: "Elixir"})

      languages = Leaderboards.get_available_languages()

      assert length(languages) == 3
      assert "Elixir" in languages
      assert "JavaScript" in languages
      assert "Python" in languages
    end

    test "returns languages in alphabetical order" do
      leaderboard_entry_fixture(%{language: "Zebra"})
      leaderboard_entry_fixture(%{language: "Alpha"})
      leaderboard_entry_fixture(%{language: "Beta"})

      languages = Leaderboards.get_available_languages()

      assert languages == ["Alpha", "Beta", "Zebra"]
    end
  end

  describe "get_available_difficulties/0" do
    test "returns empty list when no entries exist" do
      assert Leaderboards.get_available_difficulties() == []
    end

    test "returns unique difficulties from leaderboard entries" do
      leaderboard_entry_fixture(%{difficulty: :easy})
      leaderboard_entry_fixture(%{difficulty: :medium})
      # Duplicate
      leaderboard_entry_fixture(%{difficulty: :easy})
      leaderboard_entry_fixture(%{difficulty: :hard})

      difficulties = Leaderboards.get_available_difficulties()

      assert length(difficulties) == 3
      assert :easy in difficulties
      assert :medium in difficulties
      assert :hard in difficulties
    end

    test "returns difficulties in order" do
      leaderboard_entry_fixture(%{difficulty: :hard})
      leaderboard_entry_fixture(%{difficulty: :easy})
      leaderboard_entry_fixture(%{difficulty: :medium})

      difficulties = Leaderboards.get_available_difficulties()

      assert difficulties == [:easy, :hard, :medium]
    end
  end

  describe "entry_exists_for_session?/1" do
    test "returns false when no entry exists for session" do
      session = session_fixture()
      assert Leaderboards.entry_exists_for_session?(session.id) == false
    end

    test "returns true when entry exists for session" do
      entry = leaderboard_entry_fixture()
      assert Leaderboards.entry_exists_for_session?(entry.session_id) == true
    end

    test "returns false for non-existent session id" do
      invalid_id = Ecto.UUID.generate()
      assert Leaderboards.entry_exists_for_session?(invalid_id) == false
    end
  end
end
