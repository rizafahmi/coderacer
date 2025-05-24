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
        <text x="120" y="50" text-anchor="middle" class="text-brand text-large">#{cpm}</text>
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
      <text x="80" y="585" class="text-white text-small opacity-90">Challenge yourself at CodeRacer.dev</text>

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

      <text x="80" y="570" class="text-white text-large" filter="url(#glow)">CodeRacer.dev</text>

      <!-- Decorative elements -->
      <circle cx="1050" cy="540" r="25" fill="#22c55e" opacity="0.2"/>
      <circle cx="1100" cy="570" r="15" fill="#06b6d4" opacity="0.3"/>
      <circle cx="1080" cy="520" r="8" fill="#9333ea" opacity="0.4"/>
    </svg>
    """
  end
end
