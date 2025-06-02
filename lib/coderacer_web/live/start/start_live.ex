defmodule CoderacerWeb.StartLive do
  use CoderacerWeb, :live_view

  alias Coderacer.Game
  alias CoderacerWeb.Layouts

  @languages [
    {"c", "C"},
    {"clojure", "Clojure"},
    {"cpp", "C++"},
    {"csharp", "C#"},
    {"css", "CSS"},
    {"dart", "Dart"},
    {"elixir", "Elixir"},
    {"go", "Go"},
    {"haskell", "Haskell"},
    {"html", "HTML"},
    {"java", "Java"},
    {"javascript", "JavaScript"},
    {"kotlin", "Kotlin"},
    {"matlab", "MATLAB"},
    {"objectivec", "Objective-C"},
    {"perl", "Perl"},
    {"php", "PHP"},
    {"python", "Python"},
    {"r", "R"},
    {"ruby", "Ruby"},
    {"rust", "Rust"},
    {"scala", "Scala"},
    {"shell", "Shell/Bash"},
    {"sql", "SQL"},
    {"swift", "Swift"},
    {"typescript", "TypeScript"}
  ]

  @difficulties [
    {"easy", "Easy - Simple syntax and structure"},
    {"medium", "Medium - Moderate complexity"},
    {"hard", "Hard - Advanced patterns"}
  ]

  def mount(_params, _session, socket) do
    og_image_url = url(socket, ~p"/images/og-image.png")

    socket =
      socket
      |> assign(:languages, @languages)
      |> assign(:difficulties, @difficulties)
      |> assign(:og_image_url, og_image_url)

    {:ok, socket}
  end

  def handle_event("random_choice", _params, socket) do
    language = Enum.random(Enum.map(@languages, fn {value, _} -> value end))
    difficulty = Enum.random(Enum.map(@difficulties, fn {value, _} -> value end))
    start_game(socket, language, difficulty)
  end

  def handle_event("submit_choice", %{"language" => language, "difficulty" => difficulty}, socket) do
    start_game(socket, language, difficulty)
  end

  defp start_game(socket, language, difficulty) do
    with {:ok, code} <- Coderacer.AI.generate(language, difficulty),
         {:ok, session} <-
           Game.create_session(%{
             language: language,
             difficulty: String.to_atom(difficulty),
             code_challenge: code
           }) do
      {:noreply, push_navigate(socket, to: ~p"/game/#{session.id}")}
    else
      {:error, _status, _error} ->
        {:noreply, put_flash(socket, :error, "🤖 Error generating code. Rate limit exceeded.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "🔥 Error creating session")}

      _ ->
        {:noreply, put_flash(socket, :error, "Unknown error")}
    end
  end
end
