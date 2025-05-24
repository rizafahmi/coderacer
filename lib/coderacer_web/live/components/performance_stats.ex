defmodule CoderacerWeb.Components.PerformanceStats do
  @moduledoc """
  LiveComponent for displaying performance statistics in a grid layout.
  Shows CPM, accuracy, time taken, and errors.
  """
  use CoderacerWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-12">
      <div class="stat-card text-center p-6">
        <div class="text-4xl font-bold text-brand-primary mb-2">{@cpm}</div>
        <div class="text-lg font-medium text-muted">Characters/Min</div>
      </div>

      <div class="stat-card text-center p-6">
        <div class="text-4xl font-bold text-green-400 mb-2">{@accuracy}%</div>
        <div class="text-lg font-medium text-muted">Accuracy</div>
      </div>

      <div class="stat-card text-center p-6">
        <div class="text-4xl font-bold text-blue-400 mb-2">{@session.time_completion}s</div>
        <div class="text-lg font-medium text-muted">Time Taken</div>
      </div>

      <div class="stat-card text-center p-6">
        <div class="text-4xl font-bold text-red-400 mb-2">{@session.wrong}</div>
        <div class="text-lg font-medium text-muted">Errors</div>
      </div>
    </div>
    """
  end
end
