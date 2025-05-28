defmodule CoderacerWeb.Components.PerformanceAnalysis do
  @moduledoc """
  LiveComponent for displaying detailed performance analysis with share functionality.
  Shows test details, performance insights, and includes a share button.
  """
  use CoderacerWeb, :live_component

  def render(assigns) do
    func =
      "sharePerformance(#{assigns.cpm}, #{assigns.accuracy}, #{assigns.session.time_completion}, #{assigns.session.wrong}, '#{assigns.session.language}', '#{assigns.session.difficulty}')"

    assigns =
      assigns
      |> assign(:func, func)

    ~H"""
    <div class="card-modern mb-8 p-8">
      <div class="flex justify-between items-center mb-6">
        <h2 class="text-2xl font-bold text-brand-primary">Performance Analysis</h2>
        <button id="share-button" class="btn btn-outline btn-sm" onclick={@func}>
          <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.367 2.684 3 3 0 00-5.367-2.684z"
            >
            </path>
          </svg>
          Share
        </button>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
        <div>
          <h3 class="text-lg font-semibold mb-4 text-brand-secondary">Test Details</h3>
          <div class="space-y-3">
            <div class="flex justify-between">
              <span class="text-muted">Language:</span>
              <span class="font-medium">{String.capitalize(@session.language)}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-muted">Difficulty:</span>
              <span class="font-medium">{String.capitalize(to_string(@session.difficulty))}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-muted">Characters Typed:</span>
              <span class="font-medium">{@session.streak + @session.wrong}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-muted">Code Length:</span>
              <span class="font-medium">{String.length(@session.code_challenge)} chars</span>
            </div>
          </div>
        </div>

        <div>
          <h3 class="text-lg font-semibold mb-4 text-brand-secondary">Performance Insights</h3>
          <div class="space-y-2 text-sm">
            <%= if @accuracy >= 95 do %>
              <p class="text-green-400">✓ Excellent accuracy! You have great precision.</p>
            <% else %>
              <p class="text-yellow-400">• Focus on accuracy over speed for better results.</p>
            <% end %>

            <%= if @cpm >= 200 do %>
              <p class="text-green-400">✓ Great typing speed! You're above average for code.</p>
            <% else %>
              <p class="text-blue-400">
                • Practice regularly to improve your coding typing speed.
              </p>
            <% end %>

            <%= if @session.wrong <= 3 do %>
              <p class="text-green-400">✓ Very few errors - keep up the good work!</p>
            <% else %>
              <p class="text-orange-400">• Try to slow down and reduce errors for better flow.</p>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
