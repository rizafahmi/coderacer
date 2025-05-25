defmodule CoderacerWeb.Live.Components.ShareButtonTest do
  use CoderacerWeb.ConnCase
  import Phoenix.LiveViewTest

  alias CoderacerWeb.Live.Components.ShareButton

  describe "ShareButton component" do
    test "renders share button with correct props" do
      assigns = %{
        id: "test-share",
        share_title: "Test Title",
        share_text: "Test description text",
        share_url: "https://example.com/test"
      }

      html = render_component(ShareButton, assigns)

      assert html =~ "share-button-container"
      assert html =~ "share-button-test-share"
      assert html =~ "Share"
      assert html =~ "shareContent('test-share')"
    end

    test "includes correct share data in JavaScript" do
      assigns = %{
        id: "leaderboard-share",
        share_title: "CodeRacer Leaderboard 🏆",
        share_text: "Check out this leaderboard!",
        share_url: "https://coderacer.dev/share/leaderboard"
      }

      html = render_component(ShareButton, assigns)

      assert html =~ "window.shareData = window.shareData || {}"
      assert html =~ "window.shareData['leaderboard-share']"
      assert html =~ "title: 'CodeRacer Leaderboard 🏆'"
      assert html =~ "text: 'Check out this leaderboard!'"
      assert html =~ "url: 'https://coderacer.dev/share/leaderboard'"
    end

    test "includes Web Share API functionality" do
      assigns = %{
        id: "test",
        share_title: "Title",
        share_text: "Text",
        share_url: "https://example.com"
      }

      html = render_component(ShareButton, assigns)

      assert html =~ "navigator.share"
      assert html =~ "fallbackShare"
      assert html =~ "document.execCommand('copy')"
    end

    test "includes fallback copy functionality" do
      assigns = %{
        id: "test",
        share_title: "Title",
        share_text: "Text",
        share_url: "https://example.com"
      }

      html = render_component(ShareButton, assigns)

      assert html =~ "window.fallbackShare"
      assert html =~ "document.createElement('textarea')"

      assert html =~
               "textArea.value = `${shareData.title}\\n\\n${shareData.text}\\n\\n${shareData.url}`"

      assert html =~ "Copied!"
    end

    test "handles different share content types" do
      # Test session sharing
      session_assigns = %{
        id: "session-share",
        share_title: "My CodeRacer Results",
        share_text: "I scored 45 CPM with 92% accuracy!",
        share_url: "https://coderacer.dev/share/abc123"
      }

      session_html = render_component(ShareButton, session_assigns)
      assert session_html =~ "My CodeRacer Results"
      assert session_html =~ "I scored 45 CPM with 92% accuracy!"

      # Test leaderboard sharing
      leaderboard_assigns = %{
        id: "leaderboard-share",
        share_title: "CodeRacer Leaderboard 🏆",
        share_text: "Check out this CodeRacer leaderboard! 🏆",
        share_url: "https://coderacer.dev/share/leaderboard"
      }

      leaderboard_html = render_component(ShareButton, leaderboard_assigns)
      assert leaderboard_html =~ "CodeRacer Leaderboard 🏆"
      assert leaderboard_html =~ "Check out this CodeRacer leaderboard! 🏆"
    end

    test "includes error handling for share failures" do
      assigns = %{
        id: "test",
        share_title: "Title",
        share_text: "Text",
        share_url: "https://example.com"
      }

      html = render_component(ShareButton, assigns)

      assert html =~ ".catch((error) =>"
      assert html =~ "console.log('Error sharing:', error)"
      assert html =~ "fallbackShare(data, shareId)"
    end

    test "includes visual feedback for successful copy" do
      assigns = %{
        id: "test",
        share_title: "Title",
        share_text: "Text",
        share_url: "https://example.com"
      }

      html = render_component(ShareButton, assigns)

      assert html =~ "btn-success"
      assert html =~ "btn-outline"
      assert html =~ "setTimeout(() =>"
      # 2 second timeout
      assert html =~ "2000"
    end

    test "hides button when sharing is not supported" do
      assigns = %{
        id: "test",
        share_title: "Title",
        share_text: "Text",
        share_url: "https://example.com"
      }

      html = render_component(ShareButton, assigns)

      assert html =~ "document.addEventListener('DOMContentLoaded'"
      assert html =~ "!navigator.share && !document.queryCommandSupported('copy')"
      assert html =~ "shareButton.style.display = 'none'"
    end

    test "uses unique IDs for multiple share buttons" do
      assigns1 = %{
        id: "share-1",
        share_title: "Title 1",
        share_text: "Text 1",
        share_url: "https://example.com/1"
      }

      assigns2 = %{
        id: "share-2",
        share_title: "Title 2",
        share_text: "Text 2",
        share_url: "https://example.com/2"
      }

      html1 = render_component(ShareButton, assigns1)
      html2 = render_component(ShareButton, assigns2)

      assert html1 =~ "share-button-share-1"
      assert html1 =~ "window.shareData['share-1']"
      assert html1 =~ "shareContent('share-1')"

      assert html2 =~ "share-button-share-2"
      assert html2 =~ "window.shareData['share-2']"
      assert html2 =~ "shareContent('share-2')"
    end
  end
end
