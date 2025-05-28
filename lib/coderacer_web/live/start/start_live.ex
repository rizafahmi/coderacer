defmodule CoderacerWeb.StartLive do
  use CoderacerWeb, :live_view

  alias Coderacer.Game

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
    socket =
      socket
      |> assign(:languages, @languages)
      |> assign(:difficulties, @difficulties)

    {:ok, socket}
  end

  def handle_event("random_choice", _params, socket) do
    language_values = Enum.map(@languages, fn {value, _label} -> value end)
    difficulty_values = Enum.map(@difficulties, fn {value, _label} -> value end)

    language = Enum.random(language_values)
    difficulty = Enum.random(difficulty_values)

    code = Coderacer.AI.generate(language, difficulty)

    case Game.create_session(%{
           language: language,
           difficulty: String.to_atom(difficulty),
           code_challenge: code
         }) do
      {:ok, session} ->
        socket =
          socket
          |> push_navigate(to: ~p"/game/#{session.id}")

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, "Error creating session", :error)}
    end
  end

  def handle_event("submit_choice", %{"language" => language, "difficulty" => difficulty}, socket) do
    code = Coderacer.AI.generate(language, difficulty)

    case Game.create_session(%{
           language: language,
           difficulty: String.to_atom(difficulty),
           code_challenge: code
         }) do
      {:ok, session} ->
        socket =
          socket
          |> push_navigate(to: ~p"/game/#{session.id}")

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, "Error creating session", :error)}
    end
  end
end
