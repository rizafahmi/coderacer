defmodule Coderacer.ImageGenerator do
  @moduledoc """
  Generates Open Graph images for social media sharing using SVG templates.
  """

  @doc """
  Generates an SVG template for a session's results that can be rendered as PNG.
  """
  def generate_og_svg(session, cpm, accuracy) do
    language = session.language |> String.capitalize()
    difficulty = session.difficulty |> to_string() |> String.capitalize()
    time_taken = "#{session.time_completion}s"
    errors = session.wrong

    svg_template = """
    <svg width="1200" height="630" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <style>
          .bg { fill: #0f172a; }
          .primary { fill: #9333ea; }
          .secondary { fill: #22c55e; }
          .accent { fill: #06b6d4; }
          .text-white { fill: #ffffff; font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
          .text-muted { fill: #94a3b8; font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
          .text-brand { fill: #9333ea; font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
          .text-green { fill: #22c55e; font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
          .text-cyan { fill: #06b6d4; font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
          .text-red { fill: #ef4444; font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
          .text-hero { font-size: 56px; font-weight: 700; }
          .text-large { font-size: 42px; font-weight: 600; }
          .text-medium { font-size: 32px; font-weight: 600; }
          .text-small { font-size: 20px; font-weight: 500; }
          .text-xs { font-size: 16px; font-weight: 400; }
          .code { font-family: 'JetBrains Mono', 'Fira Code', 'Monaco', monospace; }
        </style>

        <!-- Background gradients -->
        <radialGradient id="bgGradient" cx="0.5" cy="0.3" r="0.8">
          <stop offset="0%" style="stop-color:#1e293b;stop-opacity:1"/>
          <stop offset="100%" style="stop-color:#0f172a;stop-opacity:1"/>
        </radialGradient>

        <linearGradient id="headerGradient" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" style="stop-color:#9333ea;stop-opacity:1"/>
          <stop offset="50%" style="stop-color:#a855f7;stop-opacity:1"/>
          <stop offset="100%" style="stop-color:#9333ea;stop-opacity:1"/>
        </linearGradient>

        <linearGradient id="cardGradient" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" style="stop-color:#1e293b;stop-opacity:0.8"/>
          <stop offset="100%" style="stop-color:#334155;stop-opacity:0.6"/>
        </linearGradient>

        <linearGradient id="accentGradient" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" style="stop-color:#9333ea;stop-opacity:0.1"/>
          <stop offset="50%" style="stop-color:#22c55e;stop-opacity:0.1"/>
          <stop offset="100%" style="stop-color:#06b6d4;stop-opacity:0.1"/>
        </linearGradient>

        <!-- Filter for subtle glow effect -->
        <filter id="glow">
          <feGaussianBlur stdDeviation="3" result="coloredBlur"/>
          <feMerge>
            <feMergeNode in="coloredBlur"/>
            <feMergeNode in="SourceGraphic"/>
          </feMerge>
        </filter>
      </defs>

      <!-- Background -->
      <rect width="1200" height="630" fill="url(#bgGradient)"/>
      <rect width="1200" height="630" fill="url(#accentGradient)"/>

      <!-- Header with enhanced gradient -->
      <rect x="0" y="0" width="1200" height="140" fill="url(#headerGradient)" rx="0"/>
      <rect x="0" y="130" width="1200" height="10" fill="url(#headerGradient)" opacity="0.3"/>

      <!-- Logo and title with better spacing -->
      <text x="80" y="90" class="text-white text-hero" filter="url(#glow)">🚀 CodeRacer Results</text>

      <!-- Performance stats with enhanced cards -->
      <g transform="translate(80, 180)">
        <!-- CPM Card -->
        <rect x="0" y="0" width="240" height="140" rx="20" fill="url(#cardGradient)" stroke="#9333ea" stroke-width="1" opacity="0.9"/>
        <text x="120" y="50" text-anchor="middle" class="text-brand text-large">#{cpm} CPM</text>
        <text x="120" y="80" text-anchor="middle" class="text-white text-small">Characters</text>
        <text x="120" y="105" text-anchor="middle" class="text-muted text-xs">per Minute</text>

        <!-- Accuracy Card -->
        <rect x="260" y="0" width="240" height="140" rx="20" fill="url(#cardGradient)" stroke="#22c55e" stroke-width="1" opacity="0.9"/>
        <text x="380" y="50" text-anchor="middle" class="text-green text-large">#{accuracy}%</text>
        <text x="380" y="80" text-anchor="middle" class="text-white text-small">Accuracy</text>
        <text x="380" y="105" text-anchor="middle" class="text-muted text-xs">Score</text>

        <!-- Time Card -->
        <rect x="520" y="0" width="240" height="140" rx="20" fill="url(#cardGradient)" stroke="#06b6d4" stroke-width="1" opacity="0.9"/>
        <text x="640" y="50" text-anchor="middle" class="text-cyan text-large">#{time_taken}</text>
        <text x="640" y="80" text-anchor="middle" class="text-white text-small">Completion</text>
        <text x="640" y="105" text-anchor="middle" class="text-muted text-xs">Time</text>

        <!-- Errors Card -->
        <rect x="780" y="0" width="240" height="140" rx="20" fill="url(#cardGradient)" stroke="#ef4444" stroke-width="1" opacity="0.9"/>
        <text x="900" y="50" text-anchor="middle" class="text-red text-large">#{errors}</text>
        <text x="900" y="80" text-anchor="middle" class="text-white text-small">Errors</text>
        <text x="900" y="105" text-anchor="middle" class="text-muted text-xs">Made</text>
      </g>

      <!-- Challenge details with better styling -->
      <g transform="translate(80, 360)">
        <rect x="0" y="0" width="520" height="100" rx="16" fill="url(#cardGradient)" stroke="#475569" stroke-width="1" opacity="0.7"/>

        <text x="30" y="35" class="text-muted text-small">Language:</text>
        <text x="150" y="35" class="text-brand text-small code">#{language}</text>

        <text x="30" y="65" class="text-muted text-small">Difficulty:</text>
        <text x="150" y="65" class="text-green text-small">#{difficulty}</text>

        <!-- Decorative code brackets -->
        <text x="450" y="35" class="text-brand text-medium code opacity-30">{ }</text>
        <text x="450" y="75" class="text-cyan text-medium code opacity-30">&lt;/&gt;</text>
      </g>

      <!-- Call to action footer with gradient -->
      <rect x="0" y="500" width="1200" height="130" fill="url(#headerGradient)" opacity="0.9"/>
      <rect x="0" y="490" width="1200" height="10" fill="url(#headerGradient)" opacity="0.3"/>

      <text x="80" y="550" class="text-white text-medium" filter="url(#glow)">🎯 Think you can do better?</text>
      <text x="80" y="585" class="text-white text-small opacity-90">Challenge yourself at #{Application.get_env(:coderacer, :base_url, "http://localhost:4000/")}</text>

      <!-- Decorative elements -->
      <circle cx="1050" cy="540" r="25" fill="#22c55e" opacity="0.2"/>
      <circle cx="1100" cy="570" r="15" fill="#06b6d4" opacity="0.3"/>
      <circle cx="1080" cy="520" r="8" fill="#9333ea" opacity="0.4"/>
    </svg>
    """

    svg_template
  end

  @doc """
  Generates an SVG template for leaderboard sharing.
  """
  def generate_leaderboard_svg(leaderboard_entries, filter_info \\ %{}) do
    # Sort entries by CPM descending and take top 5 entries for display
    top_entries =
      leaderboard_entries
      |> Enum.sort_by(& &1.cpm, :desc)
      |> Enum.take(5)

    # Generate title based on filter
    title = generate_leaderboard_title(filter_info)

    entries_html =
      top_entries
      |> Enum.with_index(1)
      |> Enum.map_join("\n", fn {entry, rank} ->
        render_leaderboard_entry(entry, rank)
      end)

    svg_template = """
    <svg width="1200" height="630" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <style>
          .bg { fill: #0f172a; }
          .primary { fill: #9333ea; }
          .secondary { fill: #22c55e; }
          .accent { fill: #06b6d4; }
          .text-white { fill: #ffffff; font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
          .text-muted { fill: #94a3b8; font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
          .text-brand { fill: #9333ea; font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
          .text-green { fill: #22c55e; font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
          .text-cyan { fill: #06b6d4; font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
          .text-red { fill: #ef4444; font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
          .text-hero { font-size: 52px; font-weight: 700; }
          .text-large { font-size: 42px; font-weight: 600; }
          .text-medium { font-size: 32px; font-weight: 600; }
          .text-small { font-size: 18px; font-weight: 500; }
          .text-xs { font-size: 14px; font-weight: 400; }
          .code { font-family: 'JetBrains Mono', 'Fira Code', 'Monaco', monospace; }
        </style>

        <!-- Background gradients -->
        <radialGradient id="bgGradient" cx="0.5" cy="0.3" r="0.8">
          <stop offset="0%" style="stop-color:#1e293b;stop-opacity:1"/>
          <stop offset="100%" style="stop-color:#0f172a;stop-opacity:1"/>
        </radialGradient>

        <linearGradient id="headerGradient" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" style="stop-color:#9333ea;stop-opacity:1"/>
          <stop offset="50%" style="stop-color:#a855f7;stop-opacity:1"/>
          <stop offset="100%" style="stop-color:#9333ea;stop-opacity:1"/>
        </linearGradient>

        <linearGradient id="cardGradient" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" style="stop-color:#1e293b;stop-opacity:0.8"/>
          <stop offset="100%" style="stop-color:#334155;stop-opacity:0.6"/>
        </linearGradient>

        <linearGradient id="accentGradient" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" style="stop-color:#9333ea;stop-opacity:0.1"/>
          <stop offset="50%" style="stop-color:#22c55e;stop-opacity:0.1"/>
          <stop offset="100%" style="stop-color:#06b6d4;stop-opacity:0.1"/>
        </linearGradient>

        <!-- Filter for subtle glow effect -->
        <filter id="glow">
          <feGaussianBlur stdDeviation="3" result="coloredBlur"/>
          <feMerge>
            <feMergeNode in="coloredBlur"/>
            <feMergeNode in="SourceGraphic"/>
          </feMerge>
        </filter>
      </defs>

      <!-- Background -->
      <rect width="1200" height="630" fill="url(#bgGradient)"/>
      <rect width="1200" height="630" fill="url(#accentGradient)"/>

      <!-- Header with enhanced gradient -->
      <rect x="0" y="0" width="1200" height="140" fill="url(#headerGradient)" rx="0"/>
      <rect x="0" y="130" width="1200" height="10" fill="url(#headerGradient)" opacity="0.3"/>

      <!-- Logo and title -->
      <text x="80" y="90" class="text-white text-hero" filter="url(#glow)">#{title}</text>

      <!-- Column Headers -->
      <g transform="translate(80, 180)">
        <rect x="0" y="0" width="1040" height="30" rx="6" fill="url(#headerGradient)" opacity="0.8"/>
        <text x="20" y="22" class="text-white text-xs">RANK</text>
        <text x="100" y="22" class="text-white text-xs">PLAYER</text>
        <text x="350" y="22" class="text-white text-xs">SPEED</text>
        <text x="500" y="22" class="text-white text-xs">ACCURACY</text>
        <text x="650" y="22" class="text-white text-xs">LANGUAGE</text>
        <text x="850" y="22" class="text-white text-xs">DIFFICULTY</text>
      </g>

      <!-- Leaderboard Entries -->
      #{entries_html}

      <!-- Call to action footer with gradient -->
      <rect x="0" y="500" width="1200" height="130" fill="url(#headerGradient)" opacity="0.9"/>
      <rect x="0" y="490" width="1200" height="10" fill="url(#headerGradient)" opacity="0.3"/>

      <text x="80" y="540" class="text-white text-medium" filter="url(#glow)">🎯 Think you can beat these scores?</text>
      <text x="80" y="575" class="text-white text-small opacity-90">Join the competition at #{Application.get_env(:coderacer, :base_url, "http://localhost:4000/")}</text>

      <!-- Decorative elements -->
      <circle cx="1050" cy="540" r="25" fill="#22c55e" opacity="0.2"/>
      <circle cx="1100" cy="570" r="15" fill="#06b6d4" opacity="0.3"/>
      <circle cx="1080" cy="520" r="8" fill="#9333ea" opacity="0.4"/>
    </svg>
    """

    svg_template
  end

  @doc """
  Generates a fallback SVG for error cases.
  """
  def generate_fallback_svg do
    """
    <svg width="1200" height="630" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <style>
          .bg { fill: #0f172a; }
          .primary { fill: #9333ea; }
          .text-white { fill: #ffffff; font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
          .text-muted { fill: #94a3b8; font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
          .text-hero { font-size: 56px; font-weight: 700; }
          .text-large { font-size: 42px; font-weight: 600; }
          .text-medium { font-size: 28px; font-weight: 500; }
          .code { font-family: 'JetBrains Mono', 'Fira Code', 'Monaco', monospace; }
        </style>

        <!-- Background gradients -->
        <radialGradient id="bgGradient" cx="0.5" cy="0.3" r="0.8">
          <stop offset="0%" style="stop-color:#1e293b;stop-opacity:1"/>
          <stop offset="100%" style="stop-color:#0f172a;stop-opacity:1"/>
        </radialGradient>

        <linearGradient id="headerGradient" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" style="stop-color:#9333ea;stop-opacity:1"/>
          <stop offset="50%" style="stop-color:#a855f7;stop-opacity:1"/>
          <stop offset="100%" style="stop-color:#9333ea;stop-opacity:1"/>
        </linearGradient>

        <linearGradient id="accentGradient" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" style="stop-color:#9333ea;stop-opacity:0.1"/>
          <stop offset="50%" style="stop-color:#22c55e;stop-opacity:0.1"/>
          <stop offset="100%" style="stop-color:#06b6d4;stop-opacity:0.1"/>
        </linearGradient>

        <!-- Filter for subtle glow effect -->
        <filter id="glow">
          <feGaussianBlur stdDeviation="3" result="coloredBlur"/>
          <feMerge>
            <feMergeNode in="coloredBlur"/>
            <feMergeNode in="SourceGraphic"/>
          </feMerge>
        </filter>
      </defs>

      <!-- Background -->
      <rect width="1200" height="630" fill="url(#bgGradient)"/>
      <rect width="1200" height="630" fill="url(#accentGradient)"/>

      <!-- Header -->
      <rect x="0" y="0" width="1200" height="140" fill="url(#headerGradient)"/>
      <rect x="0" y="130" width="1200" height="10" fill="url(#headerGradient)" opacity="0.3"/>

      <!-- Logo and title -->
      <text x="80" y="90" class="text-white text-hero" filter="url(#glow)">🚀 CodeRacer</text>

      <!-- Main content -->
      <text x="80" y="300" class="text-white text-large">Test Your Coding Typing Speed</text>
      <text x="80" y="350" class="text-muted text-medium">Challenge yourself with real code snippets</text>
      <text x="80" y="390" class="text-muted text-medium">20+ programming languages • All skill levels</text>

      <!-- Decorative code elements -->
      <text x="700" y="280" class="primary text-large code">const</text>
      <text x="800" y="280" class="text-white text-large code">speed</text>
      <text x="900" y="280" class="text-white text-large code">=</text>
      <text x="930" y="280" class="text-white text-large code">⚡</text>

      <text x="700" y="320" class="primary text-large code">function</text>
      <text x="820" y="320" class="text-white text-large code">race()</text>
      <text x="920" y="320" class="text-white text-large code">{ }</text>

      <text x="700" y="360" class="primary text-large code">&lt;challenge</text>
      <text x="850" y="360" class="text-white text-large code">/&gt;</text>

      <!-- Footer -->
      <rect x="0" y="500" width="1200" height="130" fill="url(#headerGradient)" opacity="0.9"/>
      <rect x="0" y="490" width="1200" height="10" fill="url(#headerGradient)" opacity="0.3"/>

      <text x="80" y="570" class="text-white text-large" filter="url(#glow)">#{Application.get_env(:coderacer, :base_url, "http://localhost:4000/")}</text>

      <!-- Decorative elements -->
      <circle cx="1050" cy="540" r="25" fill="#22c55e" opacity="0.2"/>
      <circle cx="1100" cy="570" r="15" fill="#06b6d4" opacity="0.3"/>
      <circle cx="1080" cy="520" r="8" fill="#9333ea" opacity="0.4"/>
    </svg>
    """
  end

  # Helper functions for leaderboard SVG generation

  defp generate_leaderboard_title(filter_info) do
    case filter_info do
      %{language: lang, difficulty: diff} when not is_nil(lang) and not is_nil(diff) ->
        lang_str = String.capitalize(lang)
        diff_str = diff |> to_string() |> String.capitalize()
        "🏆 #{lang_str} (#{diff_str}) Leaderboard"

      %{language: lang} when not is_nil(lang) ->
        "🏆 #{String.capitalize(lang)} Leaderboard"

      %{difficulty: diff} when not is_nil(diff) ->
        diff_str = diff |> to_string() |> String.capitalize()
        "🏆 #{diff_str} Leaderboard"

      _ ->
        "🏆 Global Leaderboard"
    end
  end

  defp render_leaderboard_entry(entry, rank) do
    rank_emoji = get_rank_emoji(rank)
    display_name = truncate_name(entry.player_name)
    y_pos = 220 + (rank - 1) * 50

    """
      <!-- Rank #{rank} -->
      <g transform="translate(80, #{y_pos})">
        <rect x="0" y="0" width="1040" height="40" rx="8" fill="url(#cardGradient)" stroke="#475569" stroke-width="1" opacity="0.7"/>
        <text x="20" y="28" class="text-white text-small">#{rank_emoji}</text>
        <text x="100" y="28" class="text-white text-small">#{display_name}</text>
        <text x="350" y="28" class="text-brand text-small">#{entry.cpm} CPM</text>
        <text x="500" y="28" class="text-green text-small">#{entry.accuracy}%</text>
        <text x="650" y="28" class="text-cyan text-small">#{String.capitalize(entry.language)}</text>
        <text x="850" y="28" class="text-muted text-small">#{entry.difficulty |> to_string() |> String.capitalize()}</text>
      </g>
    """
  end

  defp get_rank_emoji(rank) do
    case rank do
      1 -> "🥇"
      2 -> "🥈"
      3 -> "🥉"
      _ -> "##{rank}"
    end
  end

  defp truncate_name(name) do
    if String.length(name) > 15 do
      String.slice(name, 0, 12) <> "..."
    else
      name
    end
  end
end
