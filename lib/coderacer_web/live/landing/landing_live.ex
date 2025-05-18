defmodule CoderacerWeb.LandingLive do
  use CoderacerWeb, :live_view

  require Logger

  @agent_name :score

  @impl true
  def mount(_params, _session, socket) do
    initial_state = %{streak: 0, wrong: 0}

    code = "console.log(\"Hello, world!\")"

    socket =
      socket
      |> assign(:code, code)
      |> assign(:remaining_code, code)
      |> assign(:current_char, "")
      |> assign(:score, initial_state)

    {:ok, socket}
  end

  @impl true
  def handle_event("user_type", %{"typing" => current_char}, socket) do
    char_to_check = get_char_to_check(current_char)

    Logger.info("User typed: #{char_to_check}")
    Logger.info("Remaining code: #{socket.assigns.remaining_code}")
    remaining_code = socket.assigns.remaining_code

    socket = check_code(String.graphemes(remaining_code), char_to_check, socket)

    {:noreply, socket}
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
    socket
  end

  def check_code([h | t], char_to_check, socket) do
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
