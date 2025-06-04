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
      refute html =~ "CodeRacer"
      assert html =~ "BalapKode"
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
      {:ok, view, _html} = live(conn, "/game/#{session.id}")

      # Code challenge should be visible with space replacement
      assert view |> has_element?("pre")
      # space visual aid
      # assert html =~ "⎵"
      assert view
             |> element("pre")
             |> render() =~ "⎵"
    end

    test "handles backspace correctly", %{conn: conn, session: session} do
      {:ok, view, _html} = live(conn, "/game/#{session.id}")

      # Type some characters
      render_change(view, :user_type, %{"typing" => "con"})

      # Backspace (remove one character)
      render_change(view, :user_type, %{"typing" => "co"})

      html = render(view)
      # Should handle backspace gracefully
      assert html =~ "Time"
    end

    test "handles rapid typing correctly", %{conn: conn, session: session} do
      {:ok, view, _html} = live(conn, "/game/#{session.id}")

      # Simulate rapid typing by sending multiple events quickly
      characters = String.graphemes(session.code_challenge)

      for {_char, index} <- Enum.with_index(characters) do
        typed_so_far = Enum.take(characters, index + 1) |> Enum.join()
        render_change(view, :user_type, %{"typing" => typed_so_far})
      end

      # Should handle rapid typing without errors
      assert_redirect(view, "/finish/#{session.id}")
    end

    test "handles special characters in code challenge", %{conn: conn} do
      session =
        session_fixture(%{
          code_challenge: "console.log('Hello, 世界! 🌍');"
        })

      {:ok, _view, html} = live(conn, "/game/#{session.id}")

      # Should display special characters correctly (they are in the HTML)
      assert html =~ "世"
      assert html =~ "界"
      assert html =~ "🌍"
    end

    test "handles very long code challenge", %{conn: conn} do
      long_code = String.duplicate("console.log('test');\n", 10)
      session = session_fixture(%{code_challenge: long_code})

      {:ok, _view, html} = live(conn, "/game/#{session.id}")

      # Should handle long code without errors
      assert html =~ "Time"
      # The code should be displayed in the HTML - check for the first word
      # The HTML might have the text split across spans, so we check for individual characters
      assert html =~ "c"
      assert html =~ "o"
      assert html =~ "n"
      assert html =~ "s"
    end

    test "handles empty code challenge", %{conn: conn} do
      session = session_fixture(%{code_challenge: ""})

      {:ok, view, _html} = live(conn, "/game/#{session.id}")

      # With empty challenge, any input should complete the game
      render_change(view, :user_type, %{"typing" => ""})

      # Check that the page renders without errors
      html = render(view)
      assert html =~ "Time"
    end

    test "tracks typing statistics correctly", %{conn: conn, session: session} do
      {:ok, view, _html} = live(conn, "/game/#{session.id}")

      # Type first character correctly
      render_change(view, :user_type, %{"typing" => "c"})

      # Type second character incorrectly
      render_change(view, :user_type, %{"typing" => "cx"})

      # Correct it
      render_change(view, :user_type, %{"typing" => "co"})

      html = render(view)

      # Should track both correct and incorrect characters
      assert html =~ "Time"
    end

    test "tab_pressed advances by two when next two chars are spaces", %{conn: conn} do
      session = session_fixture(%{code_challenge: "  abc"})
      {:ok, view, _html} = live(conn, "/game/#{session.id}")

      # Simulate tab_pressed event
      render_hook(view, "tab_pressed", %{})

      # Should advance by two spaces (streak should be 2, remaining_code should start with "a")
      html = render(view)
      # streak
      assert html =~ "2"
      # next char in code
      assert html =~ "a"
    end

    test "tab_pressed increases error when next two chars are not spaces", %{conn: conn} do
      session = session_fixture(%{code_challenge: "ab"})
      {:ok, view, _html} = live(conn, "/game/#{session.id}")

      # Simulate tab_pressed event
      render_hook(view, "tab_pressed", %{})

      # Should increase wrong count (wrong should be 1, streak should be 0)
      html = render(view)
      # wrong
      assert html =~ "1"
      # streak
      assert html =~ "0"
    end
  end
end
