defmodule Coderacer.GameTest do
  use Coderacer.DataCase

  alias Coderacer.Game

  describe "sessions" do
    alias Coderacer.Game.Session

    import Coderacer.GameFixtures

    @invalid_attrs %{language: nil, difficulty: nil, time_completion: nil}

    test "list_sessions/0 returns all sessions" do
      session = session_fixture()
      assert Game.list_sessions() == [session]
    end

    test "get_session!/1 returns the session with given id" do
      session = session_fixture()
      assert Game.get_session!(session.id) == session
    end

    test "create_session/1 with valid data creates a session" do
      valid_attrs = %{
        language: "some language",
        difficulty: :easy,
        time_completion: 42,
        code_challenge: "some code challenge"
      }

      assert {:ok, %Session{} = session} = Game.create_session(valid_attrs)
      assert session.language == "some language"
      assert session.difficulty == :easy
      assert session.time_completion == 42
      assert session.code_challenge == "some code challenge"
      assert session.streak == 0
      assert session.wrong == 0
    end

    test "create_session/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Game.create_session(@invalid_attrs)
    end

    test "create_session/1 with minimal valid data" do
      minimal_attrs = %{language: "Python", difficulty: :medium}
      assert {:ok, %Session{} = session} = Game.create_session(minimal_attrs)
      assert session.language == "Python"
      assert session.difficulty == :medium
      assert session.time_completion == 0
      assert session.streak == 0
      assert session.wrong == 0
      assert session.code_challenge == ""
    end

    test "create_session/1 with all difficulty levels" do
      for difficulty <- [:easy, :medium, :hard] do
        attrs = %{language: "JavaScript", difficulty: difficulty}
        assert {:ok, %Session{} = session} = Game.create_session(attrs)
        assert session.difficulty == difficulty
      end
    end

    test "create_session/1 with invalid difficulty returns error" do
      invalid_attrs = %{language: "JavaScript", difficulty: :invalid}
      assert {:error, %Ecto.Changeset{}} = Game.create_session(invalid_attrs)
    end

    test "create_session/1 with negative time_completion" do
      attrs = %{language: "JavaScript", difficulty: :easy, time_completion: -1}
      assert {:ok, %Session{} = session} = Game.create_session(attrs)
      assert session.time_completion == -1
    end

    test "create_session/1 with negative streak and wrong counts" do
      attrs = %{
        language: "JavaScript",
        difficulty: :easy,
        streak: -5,
        wrong: -3
      }

      assert {:ok, %Session{} = session} = Game.create_session(attrs)
      assert session.streak == -5
      assert session.wrong == -3
    end

    test "create_session/1 with empty language returns error" do
      attrs = %{language: "", difficulty: :easy}
      assert {:error, %Ecto.Changeset{}} = Game.create_session(attrs)
    end

    test "create_session/1 with very long language" do
      long_language = String.duplicate("a", 1000)
      attrs = %{language: long_language, difficulty: :easy}
      assert {:ok, %Session{} = session} = Game.create_session(attrs)
      assert session.language == long_language
    end

    test "create_session/1 with very long code_challenge" do
      long_code = String.duplicate("console.log('test');\n", 100)

      attrs = %{
        language: "JavaScript",
        difficulty: :easy,
        code_challenge: long_code
      }

      assert {:ok, %Session{} = session} = Game.create_session(attrs)
      assert session.code_challenge == long_code
    end

    test "update_session/2 with valid data updates the session" do
      session = session_fixture()

      update_attrs = %{
        language: "some updated language",
        difficulty: :medium,
        time_completion: 43,
        code_challenge: "some updated code challenge",
        streak: 10,
        wrong: 5
      }

      assert {:ok, %Session{} = session} = Game.update_session(session, update_attrs)
      assert session.language == "some updated language"
      assert session.difficulty == :medium
      assert session.time_completion == 43
      assert session.code_challenge == "some updated code challenge"
      assert session.streak == 10
      assert session.wrong == 5
    end

    test "update_session/2 with invalid data returns error changeset" do
      session = session_fixture()
      assert {:error, %Ecto.Changeset{}} = Game.update_session(session, @invalid_attrs)
      assert session == Game.get_session!(session.id)
    end

    test "update_session/2 with partial data updates only provided fields" do
      session = session_fixture()
      partial_attrs = %{streak: 15}

      assert {:ok, %Session{} = updated_session} = Game.update_session(session, partial_attrs)
      assert updated_session.streak == 15
      assert updated_session.language == session.language
      assert updated_session.difficulty == session.difficulty
    end

    test "delete_session/1 deletes the session" do
      session = session_fixture()
      assert {:ok, %Session{}} = Game.delete_session(session)
      assert_raise Ecto.NoResultsError, fn -> Game.get_session!(session.id) end
    end

    test "change_session/1 returns a session changeset" do
      session = session_fixture()
      assert %Ecto.Changeset{} = Game.change_session(session)
    end

    test "change_session/2 returns a session changeset with changes" do
      session = session_fixture()
      attrs = %{language: "Updated Language"}
      changeset = Game.change_session(session, attrs)

      assert %Ecto.Changeset{} = changeset
      assert changeset.changes.language == "Updated Language"
    end

    test "get_session!/1 with invalid id raises error" do
      invalid_id = Ecto.UUID.generate()
      assert_raise Ecto.NoResultsError, fn -> Game.get_session!(invalid_id) end
    end
  end
end
