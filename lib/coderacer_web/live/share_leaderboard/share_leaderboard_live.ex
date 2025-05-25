defmodule CoderacerWeb.ShareLeaderboardLive do
  use CoderacerWeb, :live_view

  alias Coderacer.Leaderboards

  @impl true
  def mount(params, _session, socket) do
    view_type = params["view"] || "global"
    language = params["language"]
    difficulty = params["difficulty"]

    share_url = build_share_url(view_type, language, difficulty)
    og_image_url = build_og_image_url(view_type, language, difficulty)
    page_title = generate_page_title(view_type, language, difficulty)
    share_description = generate_share_description(view_type, language, difficulty)

    socket =
      socket
      |> assign(:page_title, page_title)
      |> assign(:current_view, view_type)
      |> assign(:selected_language, language)
      |> assign(:selected_difficulty, difficulty)
      |> assign(:share_url, share_url)
      |> assign(:og_image_url, og_image_url)
      |> assign(:share_description, share_description)
      |> load_leaderboard_data(view_type, language, difficulty)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full max-w-6xl mx-auto">
      <!-- Header -->
      <div class="text-center mb-8">
        <h1 class="text-4xl font-bold text-gradient mb-2">
          <%= cond do %>
            <% @current_view == "language" and not is_nil(@selected_language) and @selected_language != "" -> %>
              🏆 {String.capitalize(@selected_language)} Leaderboard
            <% @current_view == "difficulty" and not is_nil(@selected_difficulty) and @selected_difficulty != "" -> %>
              🏆 {format_difficulty(@selected_difficulty)} Difficulty Leaderboard
            <% @current_view == "combined" and not is_nil(@selected_language) and @selected_language != "" and not is_nil(@selected_difficulty) and @selected_difficulty != "" -> %>
              🏆 {String.capitalize(@selected_language)} ({format_difficulty(@selected_difficulty)}) Leaderboard
            <% true -> %>
              🏆 Global Leaderboard
          <% end %>
        </h1>
        <p class="text-xl text-muted">Top coding speed champions</p>
      </div>
      
    <!-- Share Button -->
      <%= if not Enum.empty?(@leaderboard_entries) do %>
        <div class="text-center mb-6">
          <.live_component
            module={CoderacerWeb.Live.Components.ShareButton}
            id="share-leaderboard"
            share_title="CodeRacer Leaderboard 🏆"
            share_text="Check out this CodeRacer leaderboard! 🏆"
            share_url={@share_url}
          />
        </div>
      <% end %>
      
    <!-- Leaderboard Table -->
      <%= if Enum.empty?(@leaderboard_entries) do %>
        <div class="text-center py-16">
          <div class="text-6xl mb-4">📊</div>
          <h3 class="text-2xl font-bold text-muted mb-2">No Entries Yet</h3>
          <p class="text-lg text-muted mb-6">Be the first to set a record!</p>
        </div>
      <% else %>
        <div class="overflow-x-auto mb-8">
          <table class="table table-zebra bg-slate-900/50 rounded-xl">
            <thead>
              <tr class="text-brand-primary">
                <th class="text-center">Rank</th>
                <th>Player</th>
                <th class="text-center">CPM</th>
                <th class="text-center">Accuracy</th>
                <th class="text-center">Language</th>
                <th class="text-center">Difficulty</th>
                <th class="text-center">Date</th>
              </tr>
            </thead>
            <tbody>
              <%= for {entry, index} <- Enum.with_index(@leaderboard_entries, 1) do %>
                <tr class="hover:bg-slate-800/30">
                  <td class="text-center font-bold">
                    <div class={"badge #{rank_badge_class(index)}"}>
                      {rank_display(index)}
                    </div>
                  </td>
                  <td class="font-medium text-white">
                    {entry.player_name}
                  </td>
                  <td class="text-center font-bold text-brand-primary">
                    {entry.cpm}
                  </td>
                  <td class="text-center font-bold text-green-400">
                    {entry.accuracy}%
                  </td>
                  <td class="text-center">
                    <span class="badge badge-outline">
                      {String.capitalize(entry.language)}
                    </span>
                  </td>
                  <td class="text-center">
                    <span class={"badge #{difficulty_badge_class(entry.difficulty)}"}>
                      {format_difficulty(entry.difficulty)}
                    </span>
                  </td>
                  <td class="text-center text-sm text-muted">
                    <div>{Calendar.strftime(entry.inserted_at, "%m/%d/%y")}</div>
                    <div class="text-xs opacity-75">
                      {Calendar.strftime(entry.inserted_at, "%I:%M %p")}
                    </div>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>
      
    <!-- Call to Action Section -->
      <div class="text-center py-16 bg-gradient-to-r from-purple-900/20 to-blue-900/20 rounded-xl border border-slate-700 mb-8">
        <h2 class="text-3xl font-bold text-white mb-4">🎯 Think You Can Beat These Scores?</h2>
        <p class="text-xl text-muted mb-6">Join the competition and test your coding typing skills</p>
        <div class="flex flex-col items-center gap-4">
          <a href="/" class="btn btn-primary btn-lg hover:scale-105 transition-transform">
            <svg class="w-6 h-6 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M13 10V3L4 14h7v7l9-11h-7z"
              />
            </svg>
            Start Your Challenge
          </a>
          <div class="text-sm text-muted mt-6">
            ✨ 20+ Programming Languages • All Skill Levels • Free Forever
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp load_leaderboard_data(socket, view_type, language, difficulty) do
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

  defp generate_page_title(view_type, language, difficulty) do
    case view_type do
      "language" when not is_nil(language) ->
        "#{String.capitalize(language)} Leaderboard - CodeRacer"

      "difficulty" when not is_nil(difficulty) ->
        "#{format_difficulty(difficulty)} Difficulty Leaderboard - CodeRacer"

      "combined" when not is_nil(language) and not is_nil(difficulty) ->
        "#{String.capitalize(language)} (#{format_difficulty(difficulty)}) Leaderboard - CodeRacer"

      _ ->
        "Global Leaderboard - CodeRacer"
    end
  end

  defp generate_share_description(view_type, language, difficulty) do
    case view_type do
      "language" when not is_nil(language) ->
        "Check out the top #{String.capitalize(language)} coding speed champions on CodeRacer! 🏆 See who dominates the leaderboard."

      "difficulty" when not is_nil(difficulty) ->
        "Check out the top #{format_difficulty(difficulty)} difficulty coding speed champions on CodeRacer! 🏆 See who dominates the leaderboard."

      "combined" when not is_nil(language) and not is_nil(difficulty) ->
        "Check out the top #{String.capitalize(language)} (#{format_difficulty(difficulty)}) coding speed champions on CodeRacer! 🏆 See who dominates the leaderboard."

      _ ->
        "Check out the top coding speed champions on CodeRacer! 🏆 See who dominates the global leaderboard."
    end
  end

  defp build_share_url(view_type, language, difficulty) do
    base_url = CoderacerWeb.Endpoint.url()

    params =
      []
      |> maybe_add_param(:view, view_type)
      |> maybe_add_param(:language, language)
      |> maybe_add_param(:difficulty, difficulty)
      |> Enum.reverse()
      |> URI.encode_query()

    "#{base_url}/share/leaderboard?#{params}"
  end

  defp build_og_image_url(view_type, language, difficulty) do
    base_url = CoderacerWeb.Endpoint.url()

    params =
      []
      |> maybe_add_param(:view, view_type)
      |> maybe_add_param(:language, language)
      |> maybe_add_param(:difficulty, difficulty)
      |> Enum.reverse()
      |> URI.encode_query()

    "#{base_url}/og-image/leaderboard?#{params}"
  end

  defp maybe_add_param(params, _key, nil), do: params
  defp maybe_add_param(params, _key, ""), do: params
  defp maybe_add_param(params, key, value), do: [{key, value} | params]

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
