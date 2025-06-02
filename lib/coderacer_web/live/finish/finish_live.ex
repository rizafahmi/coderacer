defmodule CoderacerWeb.FinishLive do
  use CoderacerWeb, :live_view
  require Logger

  alias Coderacer.Game
  alias Coderacer.Leaderboards
  alias CoderacerWeb.Layouts

  def mount(%{"id" => id}, _session, socket) do
    case Game.get_session(id) do
      nil ->
        {:ok, assign(socket, :error, "Session not found")}

      session ->
        # Calculate stats - CPM is the standard metric for typing tests
        cpm =
          if session.time_completion > 0,
            do: round((session.streak + session.wrong) * 60 / session.time_completion),
            else: 0

        accuracy =
          if session.streak + session.wrong > 0,
            do: round(session.streak / (session.streak + session.wrong) * 100),
            else: 0

        # Check if already submitted to leaderboard
        already_submitted = Leaderboards.entry_exists_for_session?(session.id)

        # Start streaming analysis
        start_analysis_stream(session, self())

        socket =
          socket
          |> assign(:session, session)
          |> assign(:cpm, cpm)
          |> assign(:accuracy, accuracy)
          |> assign(:already_submitted, already_submitted)
          |> assign(:player_name, "")
          |> assign(:submission_status, nil)
          |> assign(:analysis, "")
          |> assign(:analysis_streaming, true)
          |> assign(:analysis_complete, false)

        {:ok, socket}
    end
  end

  def handle_event("submit_to_leaderboard", %{"player_name" => player_name}, socket) do
    if String.trim(player_name) == "" do
      {:noreply, put_flash(socket, :error, "🔥 Please enter a player name")}
    else
      case Leaderboards.create_leaderboard_entry(%{
             player_name: String.trim(player_name),
             cpm: socket.assigns.cpm,
             accuracy: socket.assigns.accuracy,
             session_id: socket.assigns.session.id
           }) do
        {:ok, _entry} ->
          socket =
            socket
            |> assign(:already_submitted, true)
            |> assign(:submission_status, :success)
            |> put_flash(:info, "🏆 Score submitted to leaderboard!")

          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "🔥Failed to submit score. Please try again.")}
      end
    end
  end

  def handle_info({:analysis_chunk, chunk}, socket) do
    Logger.debug("Received analysis chunk in LiveView: #{inspect(String.slice(chunk, 0, 50))}...")
    current_analysis = socket.assigns.analysis
    updated_analysis = current_analysis <> chunk

    socket =
      socket
      |> assign(:analysis, updated_analysis)

    {:noreply, socket}
  end

  def handle_info(:analysis_complete, socket) do
    Logger.info("Analysis streaming completed successfully")

    socket =
      socket
      |> assign(:analysis_streaming, false)
      |> assign(:analysis_complete, true)

    {:noreply, socket}
  end

  def handle_info(:analysis_error, socket) do
    Logger.error("Analysis streaming failed with error")

    socket =
      socket
      |> assign(:analysis_streaming, false)
      |> assign(:analysis_complete, true)
      |> assign(:analysis, "Analysis temporarily unavailable. Please try refreshing the page.")

    {:noreply, socket}
  end

  defp start_analysis_stream(session, pid) do
    Logger.info("Starting analysis stream task for session #{session.id}")

    Task.start(fn ->
      try do
        Logger.info("Calling AI.analyze_stream for session #{session.id}")

        Coderacer.AI.analyze_stream(session, fn chunk ->
          Logger.debug(
            "Sending chunk to LiveView process: #{inspect(String.slice(chunk, 0, 30))}..."
          )

          send(pid, {:analysis_chunk, chunk})
        end)

        Logger.info("Analysis stream completed, sending completion message")
        send(pid, :analysis_complete)
      rescue
        error ->
          Logger.error("Analysis stream failed with error: #{inspect(error)}")
          send(pid, :analysis_error)
      end
    end)
  end
end
