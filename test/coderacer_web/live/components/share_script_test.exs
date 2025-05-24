defmodule CoderacerWeb.Components.ShareScriptTest do
  use CoderacerWeb.ConnCase
  import Phoenix.LiveViewTest
  import Coderacer.GameFixtures

  alias CoderacerWeb.Components.ShareScript

  describe "ShareScript component" do
    setup do
      session =
        session_fixture(%{
          id: "test-session-id",
          time_completion: 30,
          streak: 12,
          wrong: 1,
          language: "rust",
          difficulty: :hard
        })

      %{session: session}
    end

    test "renders share script with correct data", %{session: session} do
      assigns = %{
        cpm: 26,
        accuracy: 92,
        session: session
      }

      html = render_component(ShareScript, assigns)

      assert html =~ "sharePerformance()"
      assert html =~ "Web Share API"
      assert html =~ "fallbackShare"
      assert html =~ "CodeRacer Challenge Results"
    end

    test "includes correct performance data in share text", %{session: session} do
      assigns = %{
        cpm: 26,
        accuracy: 92,
        session: session
      }

      html = render_component(ShareScript, assigns)

      assert html =~ "26} Characters/Min"
      assert html =~ "92}% Accuracy"
      assert html =~ "30}s Time Taken"
      assert html =~ "1} Errors"
      assert html =~ "Rust"
      assert html =~ "Hard"
    end

    test "includes correct share URL", %{session: session} do
      assigns = %{
        cpm: 26,
        accuracy: 92,
        session: session
      }

      html = render_component(ShareScript, assigns)

      assert html =~ "window.location.origin + '/share/#{session.id}'"
    end

    test "includes clipboard fallback functionality", %{session: session} do
      assigns = %{
        cpm: 26,
        accuracy: 92,
        session: session
      }

      html = render_component(ShareScript, assigns)

      assert html =~ "document.execCommand('copy')"
      assert html =~ "Copied!"
      assert html =~ "btn-success"
      assert html =~ "Sharing not supported"
    end

    test "includes feature detection", %{session: session} do
      assigns = %{
        cpm: 26,
        accuracy: 92,
        session: session
      }

      html = render_component(ShareScript, assigns)

      assert html =~ "navigator.share"
      assert html =~ "document.queryCommandSupported('copy')"
      assert html =~ "DOMContentLoaded"
    end
  end
end
