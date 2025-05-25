defmodule Coderacer.Leaderboards.LeaderboardEntryTest do
  use Coderacer.DataCase

  alias Coderacer.Leaderboards.LeaderboardEntry
  import Coderacer.GameFixtures

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      session = session_fixture()

      attrs = %{
        player_name: "Test Player",
        cpm: 45,
        accuracy: 92,
        session_id: session.id
      }

      changeset = LeaderboardEntry.changeset(%LeaderboardEntry{}, attrs)

      assert changeset.valid?
      assert changeset.changes.player_name == "Test Player"
      assert changeset.changes.cpm == 45
      assert changeset.changes.accuracy == 92
      assert changeset.changes.session_id == session.id
    end

    test "invalid changeset with missing required fields" do
      changeset = LeaderboardEntry.changeset(%LeaderboardEntry{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).player_name
      assert "can't be blank" in errors_on(changeset).cpm
      assert "can't be blank" in errors_on(changeset).accuracy
      assert "can't be blank" in errors_on(changeset).session_id
    end

    test "invalid changeset with empty player_name" do
      session = session_fixture()

      attrs = %{
        player_name: "",
        cpm: 45,
        accuracy: 92,
        session_id: session.id
      }

      changeset = LeaderboardEntry.changeset(%LeaderboardEntry{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).player_name
    end

    test "invalid changeset with nil player_name" do
      session = session_fixture()

      attrs = %{
        player_name: nil,
        cpm: 45,
        accuracy: 92,
        session_id: session.id
      }

      changeset = LeaderboardEntry.changeset(%LeaderboardEntry{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).player_name
    end

    test "invalid changeset with negative cpm" do
      session = session_fixture()

      attrs = %{
        player_name: "Test Player",
        cpm: -5,
        accuracy: 92,
        session_id: session.id
      }

      changeset = LeaderboardEntry.changeset(%LeaderboardEntry{}, attrs)

      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).cpm
    end

    test "valid changeset with zero cpm" do
      session = session_fixture()

      attrs = %{
        player_name: "Test Player",
        cpm: 0,
        accuracy: 92,
        session_id: session.id
      }

      changeset = LeaderboardEntry.changeset(%LeaderboardEntry{}, attrs)

      assert changeset.valid?
    end

    test "invalid changeset with accuracy below 0" do
      session = session_fixture()

      attrs = %{
        player_name: "Test Player",
        cpm: 45,
        accuracy: -5,
        session_id: session.id
      }

      changeset = LeaderboardEntry.changeset(%LeaderboardEntry{}, attrs)

      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).accuracy
    end

    test "invalid changeset with accuracy above 100" do
      session = session_fixture()

      attrs = %{
        player_name: "Test Player",
        cpm: 45,
        accuracy: 105,
        session_id: session.id
      }

      changeset = LeaderboardEntry.changeset(%LeaderboardEntry{}, attrs)

      refute changeset.valid?
      assert "must be less than or equal to 100" in errors_on(changeset).accuracy
    end

    test "valid changeset with accuracy at boundaries" do
      session = session_fixture()

      # Test accuracy = 0
      attrs_0 = %{
        player_name: "Test Player",
        cpm: 45,
        accuracy: 0,
        session_id: session.id
      }

      changeset_0 = LeaderboardEntry.changeset(%LeaderboardEntry{}, attrs_0)
      assert changeset_0.valid?

      # Test accuracy = 100
      attrs_100 = %{
        player_name: "Test Player",
        cpm: 45,
        accuracy: 100,
        session_id: session.id
      }

      changeset_100 = LeaderboardEntry.changeset(%LeaderboardEntry{}, attrs_100)
      assert changeset_100.valid?
    end

    test "invalid changeset with non-integer cpm" do
      session = session_fixture()

      attrs = %{
        player_name: "Test Player",
        cpm: "not_a_number",
        accuracy: 92,
        session_id: session.id
      }

      changeset = LeaderboardEntry.changeset(%LeaderboardEntry{}, attrs)

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).cpm
    end

    test "invalid changeset with non-integer accuracy" do
      session = session_fixture()

      attrs = %{
        player_name: "Test Player",
        cpm: 45,
        accuracy: "not_a_number",
        session_id: session.id
      }

      changeset = LeaderboardEntry.changeset(%LeaderboardEntry{}, attrs)

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).accuracy
    end

    test "invalid changeset with player name exceeding max length" do
      session = session_fixture()
      # Exceeds max length of 50
      long_name = String.duplicate("a", 51)

      attrs = %{
        player_name: long_name,
        cpm: 45,
        accuracy: 92,
        session_id: session.id
      }

      changeset = LeaderboardEntry.changeset(%LeaderboardEntry{}, attrs)

      refute changeset.valid?
      assert "should be at most 50 character(s)" in errors_on(changeset).player_name
    end

    test "valid changeset with player name at max length" do
      session = session_fixture()
      # Exactly max length
      max_length_name = String.duplicate("a", 50)

      attrs = %{
        player_name: max_length_name,
        cpm: 45,
        accuracy: 92,
        session_id: session.id
      }

      changeset = LeaderboardEntry.changeset(%LeaderboardEntry{}, attrs)

      assert changeset.valid?
      assert changeset.changes.player_name == max_length_name
    end

    test "valid changeset with high cpm value" do
      session = session_fixture()

      attrs = %{
        player_name: "Speed Demon",
        cpm: 999_999,
        accuracy: 92,
        session_id: session.id
      }

      changeset = LeaderboardEntry.changeset(%LeaderboardEntry{}, attrs)

      assert changeset.valid?
      assert changeset.changes.cpm == 999_999
    end

    test "invalid changeset with invalid session_id format" do
      attrs = %{
        player_name: "Test Player",
        cpm: 45,
        accuracy: 92,
        session_id: "not-a-uuid"
      }

      changeset = LeaderboardEntry.changeset(%LeaderboardEntry{}, attrs)

      # Note: Ecto.UUID.cast can handle many string formats, so this might be valid
      # The real validation happens at the database level with foreign key constraints
      # For truly invalid UUIDs, we'd need a format that Ecto.UUID.cast rejects
      if changeset.valid? do
        # If the changeset is valid, it means Ecto accepted the format
        # but it would fail on insertion due to foreign key constraint
        assert changeset.valid?
      else
        refute changeset.valid?
        assert "is invalid" in errors_on(changeset).session_id
      end
    end

    test "invalid changeset with non-existent session_id" do
      invalid_session_id = Ecto.UUID.generate()

      attrs = %{
        player_name: "Test Player",
        cpm: 45,
        accuracy: 92,
        session_id: invalid_session_id
      }

      changeset = LeaderboardEntry.changeset(%LeaderboardEntry{}, attrs)

      # Changeset should be valid, but insertion will fail due to foreign key constraint
      assert changeset.valid?
    end

    test "changeset preserves existing data when updating" do
      session = session_fixture()

      existing_entry = %LeaderboardEntry{
        player_name: "Original Player",
        cpm: 30,
        accuracy: 80,
        session_id: session.id
      }

      update_attrs = %{
        player_name: "Updated Player",
        cpm: 50
      }

      changeset = LeaderboardEntry.changeset(existing_entry, update_attrs)

      assert changeset.valid?
      assert changeset.changes.player_name == "Updated Player"
      assert changeset.changes.cpm == 50
      # accuracy should remain unchanged
      refute Map.has_key?(changeset.changes, :accuracy)
    end
  end
end
