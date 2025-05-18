defmodule CoderacerWeb.LandingLiveTest do
  use CoderacerWeb.ConnCase
  import Phoenix.LiveViewTest

  describe "LandingLive" do
    test "renders initial state", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      assert html =~ "Stopwatch"
      assert html =~ "Time: 0 seconds"
    end

    test "starts stopwatch on first character input", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      refute render(view) =~ "Time: 1 seconds"

      render_change(view, :user_type, %{"typing" => "c"})
      Process.sleep(1100) # Wait for the tick
      assert render(view) =~ "Time: 1 seconds"
    end

    test "stops stopwatch when code is completed", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      render_change(view, :user_type, %{"typing" => "console.log(\"Hello, world!\")"})
      Process.sleep(100) # Allow time for the event to process
      assert render(view) =~ "Time: 0 seconds"
    end
  end
end