defmodule CoderacerWeb.GameLive do
  use CoderacerWeb, :live_view

  require Logger
  alias Coderacer.Game

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    initial_state = %{streak: 0, wrong: 0}

    session = Game.get_session!(id)
    # Convert tabs to two spaces for easier typing
    snippet = String.trim(session.code_challenge) |> String.replace("\t", "  ")
    og_image_url = url(socket, ~p"/images/og-image.png")

    socket =
      socket
      |> assign(:session, session)
      |> assign(:original_code, snippet)
      |> assign(:current_position, 0)
      |> assign(:remaining_code, snippet)
      |> assign(:display_code, format_code_for_typing(snippet, 0))
      |> assign(:current_char, "")
      |> assign(:score, initial_state)
      |> assign(:elapsed_time, %{elapsed_time: 0, running: false})
      |> assign(:og_image_url, og_image_url)

    {:ok, socket}
  end

  @impl true
  def handle_event("user_type", %{"typing" => current_char}, socket) do
    char_to_check = get_char_to_check(current_char)

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
  def handle_event("tab_pressed", _payload, socket) do
    remaining_code_graphemes = String.graphemes(socket.assigns.remaining_code)
    original_code = socket.assigns.original_code
    current_position = socket.assigns.current_position
    session_id = socket.assigns.session.id

    case remaining_code_graphemes do
      [" ", " " | t_rest] ->
        # Target has two spaces, Tab press is correct
        new_position = current_position + 2
        new_remaining_code = Enum.join(t_rest)

        new_score = %{
          streak: socket.assigns.score.streak + 2,
          wrong: socket.assigns.score.wrong
        }

        socket_after_match =
          socket
          |> assign(:current_position, new_position)
          |> assign(:remaining_code, new_remaining_code)
          |> assign(:display_code, format_code_for_typing(original_code, new_position))
          |> assign(:score, new_score)

        if Enum.empty?(t_rest) do
          # Game finished after matching the tab
          Logger.info("Finish after tab")

          Game.update_session(socket.assigns.session, %{
            streak: new_score.streak,
            wrong: new_score.wrong,
            time_completion: socket.assigns.elapsed_time.elapsed_time
          })

          {:noreply,
           socket_after_match
           |> assign(:elapsed_time, %{socket.assigns.elapsed_time | running: false})
           |> push_navigate(to: "/finish/#{session_id}")}
        else
          # Continue game
          {:noreply, socket_after_match}
        end

      _ ->
        # Target does not have two spaces, Tab press is an error
        {:noreply,
         socket
         |> assign(:score, %{streak: 0, wrong: socket.assigns.score.wrong + 1})}
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

  def format_code_for_typing(original_code, current_position) do
    graphemes = String.graphemes(original_code)

    {typed, remaining} = Enum.split(graphemes, current_position)

    typed_html = Enum.map_join(typed, "", &format_char_as_typed/1)
    cursor_html = "<span class=\"inline-block w-2 animate-blink text-brand-primary\">|</span>"
    remaining_html = Enum.map_join(remaining, "", &format_char_as_remaining/1)

    typed_html <> cursor_html <> remaining_html
  end

  defp format_char_as_typed(char) do
    case char do
      " " -> "<span class=\"text-green-100 text-[12px] px-1\">⎵</span>"
      "\r\n" -> "<span class=\"text-green-100 font-bold pl-1\">↵</span>\n"
      "\n" -> "<span class=\"text-green-100 font-bold pl-1\">↵</span>\n"
      "\r" -> "<span class=\"text-green-100 font-bold pl-1\">↵</span>\n"
      _ -> "<span class=\"text-green-100 \">#{html_escape_char(char)}</span>"
    end
  end

  defp format_char_as_remaining(char) do
    case char do
      " " -> "<span class=\"text-slate-400 opacity-60 text-[12px] px-1\">⎵</span>"
      "\r\n" -> "<span class=\"text-slate-400 opacity-60 font-bold pl-1\">↵</span>\n"
      "\n" -> "<span class=\"text-slate-400 opacity-60 font-bold pl-1\">↵</span>\n"
      "\r" -> "<span class=\"text-slate-400 opacity-60 font-bold pl-1\">↵</span>\n"
      _ -> "<span class=\"text-slate-400 opacity-60\">#{html_escape_char(char)}</span>"
    end
  end

  defp html_escape_char(char) do
    case char do
      "<" -> "&lt;"
      ">" -> "&gt;"
      "&" -> "&amp;"
      "\"" -> "&quot;"
      "'" -> "&#x27;"
      _ -> char
    end
  end

  def format_code_with_visual_aids(code) do
    code
    # Use unique markers first to avoid interference
    |> String.replace("\t", "___TAB___")
    |> String.replace(" ", "___SPACE___")
    |> String.replace("\r\n", "___CRLF___")
    |> String.replace("\n", "___LF___")
    |> String.replace("\r", "___CR___")
    # Then replace with HTML
    |> String.replace("___TAB___", "<span class=\"text-slate-500\">⇥</span>")
    |> String.replace("___SPACE___", "<span class=\"text-slate-500 text-[12px] px-1\">⎵</span>")
    |> String.replace("___CRLF___", "<span class=\"text-slate-500 font-bold pl-1\">↵</span>\n")
    |> String.replace("___LF___", "<span class=\"text-slate-500 font-bold pl-1\">↵</span>\n")
    |> String.replace("___CR___", "<span class=\"text-slate-500 font-bold pl-1\">↵</span>\n")
  end

  def check_code([], _char_to_check, socket) do
    # No characters left to check - game already completed
    socket
  end

  def check_code([h | t], char_to_check, socket) do
    cond do
      char_to_check == h and Enum.empty?(t) ->
        # Correct character and it's the last one - finish game!
        Logger.info("Finish")

        new_position = socket.assigns.current_position + 1

        socket =
          socket
          |> assign(:current_position, new_position)
          |> assign(:remaining_code, "")
          |> assign(
            :display_code,
            format_code_for_typing(socket.assigns.original_code, new_position)
          )
          |> assign(:score, %{
            streak: socket.assigns.score.streak + 1,
            wrong: socket.assigns.score.wrong
          })
          |> assign(:elapsed_time, %{socket.assigns.elapsed_time | running: false})
          |> push_navigate(to: "/finish/#{socket.assigns.session.id}")

        Game.update_session(socket.assigns.session, %{
          streak: socket.assigns.score.streak + 1,
          wrong: socket.assigns.score.wrong,
          time_completion: socket.assigns.elapsed_time.elapsed_time
        })

        socket

      char_to_check == h ->
        # Correct character but not the last one
        new_position = socket.assigns.current_position + 1
        new_remaining_code = Enum.join(t)

        socket
        |> assign(:current_position, new_position)
        |> assign(:remaining_code, new_remaining_code)
        |> assign(
          :display_code,
          format_code_for_typing(socket.assigns.original_code, new_position)
        )
        |> assign(:score, %{
          streak: socket.assigns.score.streak + 1,
          wrong: socket.assigns.score.wrong
        })

      true ->
        # Incorrect character typed
        socket
        |> assign(:score, %{streak: 0, wrong: socket.assigns.score.wrong + 1})
    end
  end
end
