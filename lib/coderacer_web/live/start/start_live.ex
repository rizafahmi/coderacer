defmodule CoderacerWeb.StartLive do
  use CoderacerWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("submit_choice", _values, socket) do
    {:noreply, socket}
  end
end
