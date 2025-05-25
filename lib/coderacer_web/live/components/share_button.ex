defmodule CoderacerWeb.Live.Components.ShareButton do
  @moduledoc """
  A flexible LiveComponent for sharing any content with Web Share API support and clipboard fallback.
  Supports both session results and leaderboard sharing.
  """
  use CoderacerWeb, :live_component

  def render(assigns) do
    script_content =
      """
      window.shareData = window.shareData || {};

      window.shareData['#{assigns.id}'] = {
        title: '#{assigns.share_title}',
        text: '#{assigns.share_text}',
        url: '#{assigns.share_url}'
      };
      """ <> get_share_script(assigns.id)

    assigns = assign(assigns, :script_content, script_content)

    ~H"""
    <div class="share-button-container">
      <button
        id={"share-button-#{@id}"}
        class="btn btn-outline btn-sm"
        onclick={Phoenix.HTML.raw("shareContent('#{@id}')")}
      >
        <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.367 2.684 3 3 0 00-5.367-2.684z"
          />
        </svg>
        Share
      </button>

      <script>
        <%= Phoenix.HTML.raw(@script_content) %>
      </script>
    </div>
    """
  end

  defp get_share_script(id) do
    """

    window.shareContent = function(shareId) {
      const data = window.shareData[shareId];
      if (!data) {
        console.error('Share data not found for ID:', shareId);
        return;
      }

      // Check if Web Share API is supported
      if (navigator.share) {
        navigator.share(data)
          .then(() => console.log('Successfully shared'))
          .catch((error) => {
            console.log('Error sharing:', error);
            fallbackShare(data, shareId);
          });
      } else {
        // Fallback for browsers that don't support Web Share API
        fallbackShare(data, shareId);
      }
    };

    window.fallbackShare = function(shareData, shareId) {
      // Create a temporary textarea to copy text to clipboard
      const textArea = document.createElement('textarea');
      textArea.value = `${shareData.title}\\n\\n${shareData.text}\\n\\n${shareData.url}`;
      document.body.appendChild(textArea);
      textArea.select();

      try {
        document.execCommand('copy');
        // Show success message
        const button = document.getElementById(`share-button-${shareId}`);
        const originalText = button.innerHTML;
        button.innerHTML = `
          <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
          </svg>
          Copied!
        `;
        button.classList.add('btn-success');
        button.classList.remove('btn-outline');

        setTimeout(() => {
          button.innerHTML = originalText;
          button.classList.remove('btn-success');
          button.classList.add('btn-outline');
        }, 2000);
      } catch (err) {
        console.error('Fallback copy failed:', err);
        // Show error message
        alert('Sharing not supported. Please copy the URL manually.');
      }

      document.body.removeChild(textArea);
    };

    // Hide share button if neither Web Share API nor clipboard is supported
    document.addEventListener('DOMContentLoaded', function() {
      if (!navigator.share && !document.queryCommandSupported('copy')) {
        const shareButton = document.getElementById('share-button-#{id}');
        if (shareButton) {
          shareButton.style.display = 'none';
        }
      }
    });
    """
  end
end
