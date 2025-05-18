defmodule CoderacerWeb.LandingLive do
  use CoderacerWeb, :live_view

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    code = "console.log(\"Hello, world!\")"

    socket =
      socket
      |> assign(:code, code)
      |> assign(:remaining_code, code)
      |> assign(:current_char, "")

    {:ok, socket}
  end

  @impl true
  def handle_event("user_type", %{"typing" => current_char}, socket) do
    char_to_check =
      current_char
      |> String.reverse()
      |> String.graphemes()
      |> List.first()

    Logger.info("User typed: #{char_to_check}")
    Logger.info("Remaining code: #{socket.assigns.remaining_code}")
    remaining_code = socket.assigns.remaining_code

    [h | t] = String.graphemes(remaining_code)

    case char_to_check == h do
      true ->
        Logger.info("Correct character typed: #{h}")

        remaining_code = t |> Enum.join()

        socket =
          socket
          |> assign(:remaining_code, remaining_code)

        {:noreply, socket}

      _ ->
        Logger.error("Incorrect character typed: #{current_char}")

        {:noreply, socket}
    end

    # Current char
  end
end
