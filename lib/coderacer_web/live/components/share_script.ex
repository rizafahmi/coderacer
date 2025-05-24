defmodule CoderacerWeb.Components.ShareScript do
  @moduledoc """
  LiveComponent that provides JavaScript functionality for sharing performance results.
  Includes Web Share API support with clipboard fallback.
  """
  use CoderacerWeb, :live_component

  def render(assigns) do
    ~H"""
    <script>
      function sharePerformance() {
        const shareData = {
          title: 'CodeRacer Challenge Results 🏆',
          text: `I just completed a coding challenge on CodeRacer!\n\n🎯 Results:\n• ${<%= @cpm %>} Characters/Min\n• ${<%= @accuracy %>}% Accuracy\n• ${<%= @session.time_completion %>}s Time Taken\n• ${<%= @session.wrong %>} Errors\n\nLanguage: ${<%= raw Jason.encode!(String.capitalize(@session.language)) %>}\nDifficulty: ${<%= raw Jason.encode!(String.capitalize(to_string(@session.difficulty))) %>}\n\nTry your own coding challenge at CodeRacer!`,
          url: window.location.origin + '/share/<%= @session.id %>'
        };

        // Check if Web Share API is supported
        if (navigator.share) {
          navigator.share(shareData)
            .then(() => console.log('Successfully shared'))
            .catch((error) => {
              console.log('Error sharing:', error);
              fallbackShare(shareData);
            });
        } else {
          // Fallback for browsers that don't support Web Share API
          fallbackShare(shareData);
        }
      }

      function fallbackShare(shareData) {
        // Create a temporary textarea to copy text to clipboard
        const textArea = document.createElement('textarea');
        textArea.value = `${shareData.title}\n\n${shareData.text}\n\n${shareData.url}`;
        document.body.appendChild(textArea);
        textArea.select();

        try {
          document.execCommand('copy');
          // Show success message
          const button = document.getElementById('share-button');
          const originalText = button.innerHTML;
          button.innerHTML = `
            <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
            </svg>
            Copied!
          `;
          button.classList.add('btn-success');

          setTimeout(() => {
            button.innerHTML = originalText;
            button.classList.remove('btn-success');
          }, 2000);
        } catch (err) {
          console.error('Fallback copy failed:', err);
          // Show error message
          alert('Sharing not supported. Please copy the URL manually.');
        }

        document.body.removeChild(textArea);
      }

      // Hide share button if neither Web Share API nor clipboard is supported
      document.addEventListener('DOMContentLoaded', function() {
        if (!navigator.share && !document.queryCommandSupported('copy')) {
          const shareButton = document.getElementById('share-button');
          if (shareButton) {
            shareButton.style.display = 'none';
          }
        }
      });
    </script>
    """
  end
end
