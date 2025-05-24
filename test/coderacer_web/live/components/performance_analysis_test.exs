defmodule CoderacerWeb.Components.PerformanceAnalysisTest do
  use CoderacerWeb.ConnCase
  import Phoenix.LiveViewTest
  import Coderacer.GameFixtures

  alias CoderacerWeb.Components.PerformanceAnalysis

  describe "PerformanceAnalysis component" do
    setup do
      session =
        session_fixture(%{
          time_completion: 45,
          streak: 8,
          wrong: 2,
          language: "python",
          difficulty: :medium,
          code_challenge: "def hello(): return 'world'"
        })

      %{session: session}
    end

    test "renders performance analysis with share button", %{session: session} do
      assigns = %{
        cpm: 13,
        accuracy: 80,
        session: session
      }

      html = render_component(PerformanceAnalysis, assigns)

      assert html =~ "Performance Analysis"
      assert html =~ "Share"
      assert html =~ "sharePerformance()"
      assert html =~ "Test Details"
      assert html =~ "Performance Insights"
    end

    test "displays test details correctly", %{session: session} do
      assigns = %{
        cpm: 13,
        accuracy: 80,
        session: session
      }

      html = render_component(PerformanceAnalysis, assigns)

      assert html =~ "Python"
      assert html =~ "Medium"
      # Characters typed (8 + 2)
      assert html =~ "10"
      assert html =~ "#{String.length(session.code_challenge)} chars"
    end

    test "shows correct performance insights for high accuracy", %{session: session} do
      assigns = %{
        cpm: 250,
        accuracy: 96,
        session: session
      }

      html = render_component(PerformanceAnalysis, assigns)

      assert html =~ "Excellent accuracy! You have great precision"
      assert html =~ "Great typing speed! You're above average"
    end

    test "shows correct performance insights for low accuracy", %{session: session} do
      assigns = %{
        cpm: 150,
        accuracy: 70,
        session: session
      }

      html = render_component(PerformanceAnalysis, assigns)

      assert html =~ "Focus on accuracy over speed"
      assert html =~ "Practice regularly to improve"
    end

    test "shows correct error feedback", %{session: session} do
      # Test with few errors
      assigns = %{
        cpm: 150,
        accuracy: 80,
        session: session
      }

      html = render_component(PerformanceAnalysis, assigns)
      assert html =~ "Very few errors - keep up the good work!"

      # Test with many errors
      session_many_errors = session_fixture(%{wrong: 10, streak: 5})

      assigns_many_errors = %{
        cpm: 150,
        accuracy: 33,
        session: session_many_errors
      }

      html_many_errors = render_component(PerformanceAnalysis, assigns_many_errors)
      assert html_many_errors =~ "Try to slow down and reduce errors"
    end
  end
end
