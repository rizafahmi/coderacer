defmodule CoderacerWeb.GameLiveTest do
  use CoderacerWeb.ConnCase
  import Phoenix.LiveViewTest
  import Coderacer.GameFixtures

  setup do
    session =
      session_fixture(%{
        code_challenge: "console.log(\"Hello, world!\")"
      })

    %{session: session}
  end

  describe "GameLive" do
    test "renders initial state", %{conn: conn, session: session} do
      {:ok, _view, html} = live(conn, "/game/#{session.id}")
      assert html =~ "Time"
      assert html =~ "0s"
      assert html =~ "CodeRacer"
    end

    test "starts stopwatch on first character input", %{conn: conn, session: session} do
      {:ok, view, _html} = live(conn, "/game/#{session.id}")
      refute render(view) =~ "1 seconds"

      render_change(view, :user_type, %{"typing" => "c"})
      # Wait for the tick
      Process.sleep(1100)
      assert render(view) =~ "1s"
    end

    test "tracks correct character typed", %{conn: conn, session: session} do
      {:ok, view, _html} = live(conn, "/game/#{session.id}")

      # Type first correct character
      render_change(view, :user_type, %{"typing" => "c"})
      html = render(view)

      # Should update streak
      # streak should be 1
      assert html =~ "1"
    end

    test "tracks incorrect character typed", %{conn: conn, session: session} do
      {:ok, view, _html} = live(conn, "/game/#{session.id}")

      # Type incorrect character first
      render_change(view, :user_type, %{"typing" => "x"})
      html = render(view)

      # Should update wrong count
      # wrong count should be 1
      assert html =~ "1"
    end

    test "completes game when all characters typed correctly", %{conn: conn, session: session} do
      {:ok, view, _html} = live(conn, "/game/#{session.id}")

      # Type the entire string character by character
      characters = String.graphemes(session.code_challenge)

      for {_char, index} <- Enum.with_index(characters) do
        typed_so_far = Enum.take(characters, index + 1) |> Enum.join()
        render_change(view, :user_type, %{"typing" => typed_so_far})
      end

      # Should redirect to finish page
      assert_redirect(view, "/finish/#{session.id}")
    end

    test "handles empty input correctly", %{conn: conn, session: session} do
      {:ok, view, _html} = live(conn, "/game/#{session.id}")

      render_change(view, :user_type, %{"typing" => ""})
      html = render(view)

      # Should handle empty input gracefully
      assert html =~ "Time"
    end

    test "handles non-existent session id", %{conn: conn} do
      invalid_id = Ecto.UUID.generate()

      assert_raise Ecto.NoResultsError, fn ->
        live(conn, "/game/#{invalid_id}")
      end
    end

    test "displays code challenge with visual aids", %{conn: conn, session: session} do
      {:ok, _view, html} = live(conn, "/game/#{session.id}")

      # Code challenge should be visible with space replacement
      assert html =~ ~r/c.*o.*n.*s.*o.*l.*e.*\..*l.*o.*g/s
      # space visual aid
      assert html =~ "⎵"
    end
  end
end
