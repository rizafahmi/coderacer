defmodule Coderacer.Game.SessionTest do
  use Coderacer.DataCase

  alias Coderacer.Game.Session

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      attrs = %{
        language: "JavaScript",
        difficulty: :medium,
        time_completion: 60,
        code_challenge: "console.log('Hello, World!');",
        streak: 10,
        wrong: 2
      }

      changeset = Session.changeset(%Session{}, attrs)

      assert changeset.valid?
      assert changeset.changes.language == "JavaScript"
      assert changeset.changes.difficulty == :medium
      assert changeset.changes.time_completion == 60
      assert changeset.changes.code_challenge == "console.log('Hello, World!');"
      assert changeset.changes.streak == 10
      assert changeset.changes.wrong == 2
    end

    test "valid changeset with minimal required fields" do
      attrs = %{
        language: "Python",
        difficulty: :easy
      }

      changeset = Session.changeset(%Session{}, attrs)

      assert changeset.valid?
      assert changeset.changes.language == "Python"
      assert changeset.changes.difficulty == :easy
    end

    test "invalid changeset with missing required fields" do
      changeset = Session.changeset(%Session{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).language
      assert "can't be blank" in errors_on(changeset).difficulty
    end

    test "invalid changeset with empty language" do
      attrs = %{
        language: "",
        difficulty: :medium
      }

      changeset = Session.changeset(%Session{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).language
    end

    test "invalid changeset with nil language" do
      attrs = %{
        language: nil,
        difficulty: :medium
      }

      changeset = Session.changeset(%Session{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).language
    end

    test "valid changeset with all difficulty levels" do
      for difficulty <- [:easy, :medium, :hard] do
        attrs = %{
          language: "Elixir",
          difficulty: difficulty
        }

        changeset = Session.changeset(%Session{}, attrs)

        assert changeset.valid?
        assert changeset.changes.difficulty == difficulty
      end
    end

    test "invalid changeset with invalid difficulty" do
      attrs = %{
        language: "Elixir",
        difficulty: :invalid_difficulty
      }

      changeset = Session.changeset(%Session{}, attrs)

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).difficulty
    end

    test "valid changeset with negative time_completion" do
      attrs = %{
        language: "JavaScript",
        difficulty: :easy,
        time_completion: -10
      }

      changeset = Session.changeset(%Session{}, attrs)

      assert changeset.valid?
      assert changeset.changes.time_completion == -10
    end

    test "valid changeset with zero time_completion" do
      attrs = %{
        language: "JavaScript",
        difficulty: :easy,
        time_completion: 0
      }

      changeset = Session.changeset(%Session{}, attrs)

      assert changeset.valid?
      # time_completion has a default value of 0, so it won't appear in changes when set to 0
      # We should check the data instead
      session = Ecto.Changeset.apply_changes(changeset)
      assert session.time_completion == 0
    end

    test "valid changeset with negative streak and wrong counts" do
      attrs = %{
        language: "JavaScript",
        difficulty: :easy,
        streak: -5,
        wrong: -3
      }

      changeset = Session.changeset(%Session{}, attrs)

      assert changeset.valid?
      assert changeset.changes.streak == -5
      assert changeset.changes.wrong == -3
    end

    test "valid changeset with zero streak and wrong counts" do
      attrs = %{
        language: "JavaScript",
        difficulty: :easy,
        streak: 0,
        wrong: 0
      }

      changeset = Session.changeset(%Session{}, attrs)

      assert changeset.valid?
      # streak and wrong have default values of 0, so they won't appear in changes when set to 0
      # We should check the data instead
      session = Ecto.Changeset.apply_changes(changeset)
      assert session.streak == 0
      assert session.wrong == 0
    end

    test "valid changeset with very long language name" do
      long_language = String.duplicate("a", 1000)

      attrs = %{
        language: long_language,
        difficulty: :easy
      }

      changeset = Session.changeset(%Session{}, attrs)

      assert changeset.valid?
      assert changeset.changes.language == long_language
    end

    test "valid changeset with very long code_challenge" do
      long_code = String.duplicate("console.log('test');\n", 100)

      attrs = %{
        language: "JavaScript",
        difficulty: :easy,
        code_challenge: long_code
      }

      changeset = Session.changeset(%Session{}, attrs)

      assert changeset.valid?
      assert changeset.changes.code_challenge == long_code
    end

    test "valid changeset with empty code_challenge" do
      attrs = %{
        language: "JavaScript",
        difficulty: :easy,
        code_challenge: ""
      }

      changeset = Session.changeset(%Session{}, attrs)

      assert changeset.valid?
      # code_challenge has a default value of "", so it won't appear in changes when set to ""
      # We should check the data instead
      session = Ecto.Changeset.apply_changes(changeset)
      assert session.code_challenge == ""
    end

    test "invalid changeset with non-integer time_completion" do
      attrs = %{
        language: "JavaScript",
        difficulty: :easy,
        time_completion: "not_a_number"
      }

      changeset = Session.changeset(%Session{}, attrs)

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).time_completion
    end

    test "invalid changeset with non-integer streak" do
      attrs = %{
        language: "JavaScript",
        difficulty: :easy,
        streak: "not_a_number"
      }

      changeset = Session.changeset(%Session{}, attrs)

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).streak
    end

    test "invalid changeset with non-integer wrong" do
      attrs = %{
        language: "JavaScript",
        difficulty: :easy,
        wrong: "not_a_number"
      }

      changeset = Session.changeset(%Session{}, attrs)

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).wrong
    end

    test "changeset preserves existing data when updating" do
      existing_session = %Session{
        language: "Original Language",
        difficulty: :easy,
        time_completion: 30,
        code_challenge: "original code",
        streak: 5,
        wrong: 1
      }

      update_attrs = %{
        language: "Updated Language",
        time_completion: 60
      }

      changeset = Session.changeset(existing_session, update_attrs)

      assert changeset.valid?
      assert changeset.changes.language == "Updated Language"
      assert changeset.changes.time_completion == 60
      # Other fields should remain unchanged
      refute Map.has_key?(changeset.changes, :difficulty)
      refute Map.has_key?(changeset.changes, :code_challenge)
      refute Map.has_key?(changeset.changes, :streak)
      refute Map.has_key?(changeset.changes, :wrong)
    end

    test "changeset with special characters in language" do
      attrs = %{
        language: "C++",
        difficulty: :hard
      }

      changeset = Session.changeset(%Session{}, attrs)

      assert changeset.valid?
      assert changeset.changes.language == "C++"
    end

    test "changeset with unicode characters in code_challenge" do
      attrs = %{
        language: "JavaScript",
        difficulty: :easy,
        code_challenge: "console.log('Hello 世界! 🌍');"
      }

      changeset = Session.changeset(%Session{}, attrs)

      assert changeset.valid?
      assert changeset.changes.code_challenge == "console.log('Hello 世界! 🌍');"
    end

    test "changeset with very high numeric values" do
      attrs = %{
        language: "JavaScript",
        difficulty: :easy,
        time_completion: 999_999,
        streak: 999_999,
        wrong: 999_999
      }

      changeset = Session.changeset(%Session{}, attrs)

      assert changeset.valid?
      assert changeset.changes.time_completion == 999_999
      assert changeset.changes.streak == 999_999
      assert changeset.changes.wrong == 999_999
    end
  end
end
