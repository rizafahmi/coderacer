defmodule CoderacerWeb.Components.PerformanceStatsTest do
  use CoderacerWeb.ConnCase
  import Phoenix.LiveViewTest
  import Coderacer.GameFixtures

  alias CoderacerWeb.Components.PerformanceStats

  describe "PerformanceStats component" do
    setup do
      session =
        session_fixture(%{
          time_completion: 60,
          streak: 15,
          wrong: 3,
          language: "elixir",
          difficulty: :hard
        })

      %{session: session}
    end

    test "renders performance statistics correctly", %{session: session} do
      # Calculate expected values
      cpm = round((session.streak + session.wrong) * 60 / session.time_completion)
      accuracy = round(session.streak / (session.streak + session.wrong) * 100)

      assigns = %{
        cpm: cpm,
        accuracy: accuracy,
        session: session
      }

      html = render_component(PerformanceStats, assigns)

      assert html =~ "#{cpm}"
      assert html =~ "Characters/Min"
      assert html =~ "#{accuracy}%"
      assert html =~ "Accuracy"
      assert html =~ "#{session.time_completion}s"
      assert html =~ "Time Taken"
      assert html =~ "#{session.wrong}"
      assert html =~ "Errors"
    end

    test "handles zero values correctly" do
      session =
        session_fixture(%{
          time_completion: 0,
          streak: 0,
          wrong: 0
        })

      assigns = %{
        cpm: 0,
        accuracy: 0,
        session: session
      }

      html = render_component(PerformanceStats, assigns)

      assert html =~ "0"
      assert html =~ "Characters/Min"
      assert html =~ "0%"
      assert html =~ "Accuracy"
    end
  end
end
