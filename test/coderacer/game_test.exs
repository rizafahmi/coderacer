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
    end

    test "create_session/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Game.create_session(@invalid_attrs)
    end

    test "update_session/2 with valid data updates the session" do
      session = session_fixture()

      update_attrs = %{
        language: "some updated language",
        difficulty: :medium,
        time_completion: 43,
        code_challenge: "some updated code challenge"
      }

      assert {:ok, %Session{} = session} = Game.update_session(session, update_attrs)
      assert session.language == "some updated language"
      assert session.difficulty == :medium
      assert session.time_completion == 43
      assert session.code_challenge == "some updated code challenge"
    end

    test "update_session/2 with invalid data returns error changeset" do
      session = session_fixture()
      assert {:error, %Ecto.Changeset{}} = Game.update_session(session, @invalid_attrs)
      assert session == Game.get_session!(session.id)
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
  end
end
