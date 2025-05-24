defmodule CoderacerWeb.LeaderboardLive do
  use CoderacerWeb, :live_view

  alias Coderacer.Leaderboards

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:current_view, "global")
      |> assign(:selected_language, nil)
      |> assign(:selected_difficulty, nil)
      |> assign(:available_languages, Leaderboards.get_available_languages())
      |> assign(:available_difficulties, Leaderboards.get_available_difficulties())
      |> load_leaderboard_data("global")

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    view_type = params["view"] || "global"
    language = params["language"]
    difficulty = params["difficulty"]

    socket =
      socket
      |> assign(:current_view, view_type)
      |> assign(:selected_language, language)
      |> assign(:selected_difficulty, difficulty)
      |> load_leaderboard_data(view_type, language, difficulty)

    {:noreply, socket}
  end

  @impl true
  def handle_event("switch_view", %{"view" => view_type}, socket) do
    socket =
      socket
      |> push_patch(to: "/leaderboard?view=#{view_type}")

    {:noreply, socket}
  end

  @impl true
  def handle_event("filter_language", %{"language" => language}, socket) do
    socket =
      socket
      |> push_patch(to: "/leaderboard?view=language&language=#{language}")

    {:noreply, socket}
  end

  @impl true
  def handle_event("filter_difficulty", %{"difficulty" => difficulty}, socket) do
    socket =
      socket
      |> push_patch(to: "/leaderboard?view=difficulty&difficulty=#{difficulty}")

    {:noreply, socket}
  end

  defp load_leaderboard_data(socket, view_type, language \\ nil, difficulty \\ nil) do
    entries =
      case view_type do
        "global" ->
          Leaderboards.get_global_leaderboard()

        "language" when not is_nil(language) ->
          Leaderboards.get_language_leaderboard(language)

        "difficulty" when not is_nil(difficulty) ->
          difficulty_atom = String.to_existing_atom(difficulty)
          Leaderboards.get_difficulty_leaderboard(difficulty_atom)

        "combined" when not is_nil(language) and not is_nil(difficulty) ->
          difficulty_atom = String.to_existing_atom(difficulty)
          Leaderboards.get_language_difficulty_leaderboard(language, difficulty_atom)

        _ ->
          Leaderboards.get_global_leaderboard()
      end

    assign(socket, :leaderboard_entries, entries)
  end

  defp format_difficulty(difficulty) when is_atom(difficulty) do
    difficulty |> to_string() |> String.capitalize()
  end

  defp format_difficulty(difficulty) when is_binary(difficulty) do
    String.capitalize(difficulty)
  end

  defp rank_display(1), do: "🥇"
  defp rank_display(2), do: "🥈"
  defp rank_display(3), do: "🥉"
  defp rank_display(rank), do: "##{rank}"

  defp rank_badge_class(1), do: "badge-warning text-yellow-900"
  defp rank_badge_class(2), do: "badge-info text-gray-900"
  defp rank_badge_class(3), do: "badge-accent text-amber-900"
  defp rank_badge_class(_), do: "badge-outline"

  defp difficulty_badge_class(:easy), do: "badge-success"
  defp difficulty_badge_class(:medium), do: "badge-warning"
  defp difficulty_badge_class(:hard), do: "badge-error"
  defp difficulty_badge_class(_), do: "badge-outline"
end
