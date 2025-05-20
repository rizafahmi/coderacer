defmodule CoderacerWeb.GameLiveTest do
  use CoderacerWeb.ConnCase
  import Phoenix.LiveViewTest
  import Coderacer.GameFixtures

  setup do
    session = session_fixture()
    %{session: session}
  end

  describe "GameLive" do
    test "renders initial state", %{conn: conn, session: session} do
      {:ok, _view, html} = live(conn, "/game/#{session.id}")
      assert html =~ "Time"
      assert html =~ "0 seconds"
    end

    test "starts stopwatch on first character input", %{conn: conn, session: session} do
      {:ok, view, _html} = live(conn, "/game/#{session.id}")
      refute render(view) =~ "1 seconds"

      render_change(view, :user_type, %{"typing" => "c"})
      # Wait for the tick
      Process.sleep(1100)
      assert render(view) =~ "1 seconds"
    end

    test "stops stopwatch when code is completed", %{conn: conn, session: session} do
      {:ok, view, _html} = live(conn, "/game/#{session.id}")
      render_change(view, :user_type, %{"typing" => "console.log(\"Hello, world!\")"})
      # Allow time for the event to process
      Process.sleep(100)
      assert render(view) =~ "0 seconds"
    end
  end
end
