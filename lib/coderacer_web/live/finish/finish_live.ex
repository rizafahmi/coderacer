defmodule CoderacerWeb.FinishLive do
  use CoderacerWeb, :live_view

  alias Coderacer.Game

  def mount(%{"id" => id}, _session, socket) do
    session = Game.get_session!(id)

    # Calculate stats - CPM is the standard metric for typing tests
    cpm =
      if session.time_completion > 0,
        do: round((session.streak + session.wrong) * 60 / session.time_completion),
        else: 0

    accuracy =
      if session.streak + session.wrong > 0,
        do: round(session.streak / (session.streak + session.wrong) * 100),
        else: 0

    socket =
      socket
      |> assign(:session, session)
      |> assign(:cpm, cpm)
      |> assign(:accuracy, accuracy)

    {:ok, socket}
  end
end
