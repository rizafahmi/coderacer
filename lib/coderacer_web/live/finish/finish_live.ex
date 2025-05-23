defmodule CoderacerWeb.FinishLive do
  use CoderacerWeb, :live_view

  def mount(%{"id" => id}, _session, socket) do
    socket =
      socket
      |> assign(:id, id)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1>Finish</h1>
      <pre>{inspect(@id)}</pre>
    </div>
    """
  end
end
