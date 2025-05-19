defmodule CoderacerWeb.LandingLive do
  use CoderacerWeb, :live_view

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    initial_state = %{streak: 0, wrong: 0}

    # code = Coderacer.AI.generate("JavaScript", 2, "easy")
    # code =
    #   "const arr = [];\nfor (let i = 0; i < 10; i++) {\n  arr.push(i * 2);\n}\n\nfunction greet(name) {\n  console.log('Hello, ' + name + '!');\n}\n\ngreet('World');\n\nconst obj = {\n  name: 'Example',\n  value: 123\n};\n\nconsole.log(obj.name);\nconsole.log(arr);\n"

    socket =
      socket
      # |> assign(:code, code)
      |> assign(:remaining_code, "")
      |> assign(:current_char, "")
      |> assign(:score, initial_state)
      |> assign(:elapsed_time, %{elapsed_time: 0, running: false})

    {:ok, socket}
  end

  @impl true
  def handle_event("gen-code", _value, socket) do
    # code = "const arr = [];"
    code = Coderacer.AI.generate("Clojure", 15, "easy")

    socket =
      socket
      |> assign(:remaining_code, code)

    {:noreply, socket}
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
