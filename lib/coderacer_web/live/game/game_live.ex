defmodule CoderacerWeb.GameLive do
  use CoderacerWeb, :live_view

  require Logger
  alias Coderacer.Game

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    initial_state = %{streak: 0, wrong: 0}

    session = Game.get_session!(id)

    socket =
      socket
      |> assign(:session, session)
      |> assign(:remaining_code, session.code_challenge)
      |> assign(:current_char, "")
      |> assign(:score, initial_state)
      |> assign(:elapsed_time, %{elapsed_time: 0, running: false})

    {:ok, socket}
  end

  @impl true
  def handle_event("user_type", %{"typing" => current_char}, socket) do
    char_to_check = get_char_to_check(current_char)

    Logger.info("User typed: #{char_to_check}")
    Logger.info("Remaining code: #{socket.assigns.remaining_code}")
    remaining_code = socket.assigns.remaining_code

    socket =
      case socket.assigns.elapsed_time.running do
        false ->
          Process.send_after(self(), :tick, 1000)
          assign(socket, :elapsed_time, %{socket.assigns.elapsed_time | running: true})

        true ->
          socket
      end

    socket = check_code(String.graphemes(remaining_code), char_to_check, socket)

    {:noreply, socket}
  end

  @impl true
  def handle_event("start_stopwatch", _params, socket) do
    if socket.assigns.elapsed_time.running do
      {:noreply, assign(socket, :elapsed_time, %{socket.assigns.elapsed_time | running: false})}
    else
      Process.send_after(self(), :tick, 1000)
      {:noreply, assign(socket, :elapsed_time, %{socket.assigns.elapsed_time | running: true})}
    end
  end

  @impl true
  def handle_info(:tick, socket) do
    if socket.assigns.elapsed_time.running do
      Process.send_after(self(), :tick, 1000)

      {:noreply,
       assign(socket, :elapsed_time, %{
         socket.assigns.elapsed_time
         | elapsed_time: socket.assigns.elapsed_time.elapsed_time + 1
       })}
    else
      {:noreply, socket}
    end
  end

  def get_char_to_check(current_char) do
    current_char
    |> String.reverse()
    |> String.graphemes()
    |> List.first()
  end

  def check_code([], _char_to_check, socket) do
    # No characters left to check
    Logger.info("Finish")

    socket =
      socket
      |> assign(:elapsed_time, %{socket.assigns.elapsed_time | running: false})

    Game.update_session(socket.assigns.session, %{
      streak: socket.assigns.score.streak,
      wrong: socket.assigns.score.wrong,
      time_completion: socket.assigns.elapsed_time.elapsed_time
    })

    # Show result modal

    socket
  end

  def check_code([h | t], char_to_check, socket) do
    socket =
      case Enum.empty?(t) do
        true ->
          socket
          |> assign(:elapsed_time, %{socket.assigns.elapsed_time | running: false})

        false ->
          socket
      end

    case char_to_check == h do
      true ->
        # Correct character typed
        new_remaining_code = Enum.join(t)

        socket =
          socket
          |> assign(:remaining_code, new_remaining_code)
          |> assign(:score, %{
            streak: socket.assigns.score.streak + 1,
            wrong: socket.assigns.score.wrong
          })

        socket

      false ->
        # Incorrect character typed
        socket =
          socket
          |> assign(:score, %{streak: 0, wrong: socket.assigns.score.wrong + 1})

        socket
    end
  end
end
