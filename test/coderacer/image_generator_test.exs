defmodule Coderacer.ImageGeneratorTest do
  use Coderacer.DataCase
  import Coderacer.GameFixtures

  alias Coderacer.ImageGenerator

  describe "generate_og_svg/3" do
    test "generates SVG for session with performance data" do
      session =
        session_fixture(%{
          time_completion: 60,
          streak: 30,
          wrong: 5,
          language: "elixir",
          difficulty: :medium
        })

      cpm = 35
      accuracy = 85

      svg = ImageGenerator.generate_og_svg(session, cpm, accuracy)

      assert svg =~ "<svg width=\"1200\" height=\"630\""
      assert svg =~ "35"
      assert svg =~ "85%"
      assert svg =~ "Elixir"
      assert svg =~ "Medium"
      assert svg =~ "CodeRacer"
    end

    test "includes proper SVG structure and styling" do
      session = session_fixture()
      svg = ImageGenerator.generate_og_svg(session, 40, 90)

      assert svg =~ "xmlns=\"http://www.w3.org/2000/svg\""
      assert svg =~ "<defs>"
      assert svg =~ "<style>"
      assert svg =~ "fill:"
      assert svg =~ "font-family:"
      assert svg =~ "</svg>"
    end

    test "handles zero values gracefully" do
      session = session_fixture(%{time_completion: 0, streak: 0, wrong: 0})
      svg = ImageGenerator.generate_og_svg(session, 0, 0)

      assert svg =~ "0"
      assert svg =~ "0%"
      assert svg =~ "<svg"
    end
  end

  describe "generate_leaderboard_svg/2" do
    setup do
      entries = [
        %{
          player_name: "Alice",
          cpm: 45,
          accuracy: 92,
          language: "elixir",
          difficulty: :easy,
          inserted_at: ~U[2025-01-01 12:00:00Z]
        },
        %{
          player_name: "Bob",
          cpm: 38,
          accuracy: 88,
          language: "javascript",
          difficulty: :medium,
          inserted_at: ~U[2025-01-01 11:00:00Z]
        },
        %{
          player_name: "Charlie",
          cpm: 52,
          accuracy: 95,
          language: "elixir",
          difficulty: :hard,
          inserted_at: ~U[2025-01-01 10:00:00Z]
        }
      ]

      %{entries: entries}
    end

    test "generates global leaderboard SVG", %{entries: entries} do
      svg = ImageGenerator.generate_leaderboard_svg(entries, %{})

      assert svg =~ "<svg width=\"1200\" height=\"630\""
      assert svg =~ "🏆 Global Leaderboard"
      assert svg =~ "Alice"
      assert svg =~ "Bob"
      assert svg =~ "Charlie"
      assert svg =~ "45 CPM"
      assert svg =~ "38 CPM"
      assert svg =~ "52 CPM"
      assert svg =~ "92%"
      assert svg =~ "88%"
      assert svg =~ "95%"
    end

    test "generates language-filtered leaderboard SVG", %{entries: entries} do
      filter_info = %{language: "elixir"}
      svg = ImageGenerator.generate_leaderboard_svg(entries, filter_info)

      assert svg =~ "🏆 Elixir Leaderboard"
      assert svg =~ "Alice"
      assert svg =~ "Charlie"
      assert svg =~ "Elixir"
    end

    test "generates difficulty-filtered leaderboard SVG", %{entries: entries} do
      filter_info = %{difficulty: :easy}
      svg = ImageGenerator.generate_leaderboard_svg(entries, filter_info)

      assert svg =~ "🏆 Easy Leaderboard"
      assert svg =~ "Easy"
    end

    test "generates combined filter leaderboard SVG", %{entries: entries} do
      filter_info = %{language: "elixir", difficulty: :hard}
      svg = ImageGenerator.generate_leaderboard_svg(entries, filter_info)

      assert svg =~ "🏆 Elixir (Hard) Leaderboard"
      assert svg =~ "Elixir"
      assert svg =~ "Hard"
    end

    test "includes rank emojis for top 3", %{entries: entries} do
      svg = ImageGenerator.generate_leaderboard_svg(entries, %{})

      assert svg =~ "🥇"
      assert svg =~ "🥈"
      assert svg =~ "🥉"
    end

    test "includes column headers", %{entries: entries} do
      svg = ImageGenerator.generate_leaderboard_svg(entries, %{})

      assert svg =~ "RANK"
      assert svg =~ "PLAYER"
      assert svg =~ "SPEED"
      assert svg =~ "ACCURACY"
      assert svg =~ "LANGUAGE"
      assert svg =~ "DIFFICULTY"
    end

    test "includes call-to-action footer", %{entries: entries} do
      svg = ImageGenerator.generate_leaderboard_svg(entries, %{})

      assert svg =~ "Think you can beat these scores?"
      assert svg =~ "http://localhost:4000/"
    end

    test "limits to top 5 entries" do
      # Create 7 entries
      many_entries = [
        %{
          player_name: "Player1",
          cpm: 60,
          accuracy: 95,
          language: "elixir",
          difficulty: :easy,
          inserted_at: ~U[2025-01-01 12:00:00Z]
        },
        %{
          player_name: "Player2",
          cpm: 55,
          accuracy: 90,
          language: "elixir",
          difficulty: :easy,
          inserted_at: ~U[2025-01-01 12:00:00Z]
        },
        %{
          player_name: "Player3",
          cpm: 50,
          accuracy: 85,
          language: "elixir",
          difficulty: :easy,
          inserted_at: ~U[2025-01-01 12:00:00Z]
        },
        %{
          player_name: "Player4",
          cpm: 45,
          accuracy: 80,
          language: "elixir",
          difficulty: :easy,
          inserted_at: ~U[2025-01-01 12:00:00Z]
        },
        %{
          player_name: "Player5",
          cpm: 40,
          accuracy: 75,
          language: "elixir",
          difficulty: :easy,
          inserted_at: ~U[2025-01-01 12:00:00Z]
        },
        %{
          player_name: "Player6",
          cpm: 35,
          accuracy: 70,
          language: "elixir",
          difficulty: :easy,
          inserted_at: ~U[2025-01-01 12:00:00Z]
        },
        %{
          player_name: "Player7",
          cpm: 30,
          accuracy: 65,
          language: "elixir",
          difficulty: :easy,
          inserted_at: ~U[2025-01-01 12:00:00Z]
        }
      ]

      svg = ImageGenerator.generate_leaderboard_svg(many_entries, %{})

      # Should include first 5 players
      assert svg =~ "Player1"
      assert svg =~ "Player2"
      assert svg =~ "Player3"
      assert svg =~ "Player4"
      assert svg =~ "Player5"

      # Should NOT include players 6 and 7
      refute svg =~ "Player6"
      refute svg =~ "Player7"
    end

    test "truncates long player names" do
      long_name_entries = [
        %{
          player_name: "ThisIsAVeryLongPlayerNameThatShouldBeTruncated",
          cpm: 45,
          accuracy: 92,
          language: "elixir",
          difficulty: :easy,
          inserted_at: ~U[2025-01-01 12:00:00Z]
        }
      ]

      svg = ImageGenerator.generate_leaderboard_svg(long_name_entries, %{})

      assert svg =~ "ThisIsAVeryL..."
      refute svg =~ "ThisIsAVeryLongPlayerNameThatShouldBeTruncated"
    end

    test "handles empty entries list" do
      svg = ImageGenerator.generate_leaderboard_svg([], %{})

      # Should still generate valid SVG structure
      assert svg =~ "<svg width=\"1200\" height=\"630\""
      assert svg =~ "🏆 Global Leaderboard"
      # But no player data
      refute svg =~ "🥇"
    end
  end

  describe "generate_fallback_svg/0" do
    test "generates fallback SVG with correct structure" do
      svg = ImageGenerator.generate_fallback_svg()

      assert svg =~ "<svg width=\"1200\" height=\"630\""
      assert svg =~ "🚀 CodeRacer"
      assert svg =~ "Test Your Coding Typing Speed"
      assert svg =~ "Challenge yourself with real code snippets"
      assert svg =~ "20+ programming languages"
      assert svg =~ "http://localhost:4000/"
    end

    test "includes proper styling and gradients" do
      svg = ImageGenerator.generate_fallback_svg()

      assert svg =~ "<defs>"
      assert svg =~ "<style>"
      assert svg =~ "radialGradient"
      assert svg =~ "linearGradient"
      assert svg =~ "fill:"
      assert svg =~ "font-family:"
    end

    test "includes decorative code elements" do
      svg = ImageGenerator.generate_fallback_svg()

      assert svg =~ "const"
      assert svg =~ "speed"
      assert svg =~ "function"
      assert svg =~ "race()"
      assert svg =~ "&lt;challenge"
    end
  end

  describe "helper functions" do
    test "generate_leaderboard_title/1 creates correct titles" do
      # Test through the public function since helpers are private
      svg_global = ImageGenerator.generate_leaderboard_svg([], %{})
      assert svg_global =~ "🏆 Global Leaderboard"

      svg_lang = ImageGenerator.generate_leaderboard_svg([], %{language: "elixir"})
      assert svg_lang =~ "🏆 Elixir Leaderboard"

      svg_diff = ImageGenerator.generate_leaderboard_svg([], %{difficulty: :hard})
      assert svg_diff =~ "🏆 Hard Leaderboard"

      svg_combined =
        ImageGenerator.generate_leaderboard_svg([], %{language: "rust", difficulty: :medium})

      assert svg_combined =~ "🏆 Rust (Medium) Leaderboard"
    end

    test "rank emojis are displayed correctly" do
      entries = [
        %{
          player_name: "First",
          cpm: 50,
          accuracy: 95,
          language: "elixir",
          difficulty: :easy,
          inserted_at: ~U[2025-01-01 12:00:00Z]
        },
        %{
          player_name: "Second",
          cpm: 45,
          accuracy: 90,
          language: "elixir",
          difficulty: :easy,
          inserted_at: ~U[2025-01-01 12:00:00Z]
        },
        %{
          player_name: "Third",
          cpm: 40,
          accuracy: 85,
          language: "elixir",
          difficulty: :easy,
          inserted_at: ~U[2025-01-01 12:00:00Z]
        },
        %{
          player_name: "Fourth",
          cpm: 35,
          accuracy: 80,
          language: "elixir",
          difficulty: :easy,
          inserted_at: ~U[2025-01-01 12:00:00Z]
        }
      ]

      svg = ImageGenerator.generate_leaderboard_svg(entries, %{})

      # Check that emojis appear in correct order
      first_pos = String.split(svg, "🥇") |> hd() |> String.length()
      second_pos = String.split(svg, "🥈") |> hd() |> String.length()
      third_pos = String.split(svg, "🥉") |> hd() |> String.length()
      fourth_pos = String.split(svg, ">#4<") |> hd() |> String.length()

      assert first_pos < second_pos
      assert second_pos < third_pos
      assert third_pos < fourth_pos
    end
  end
end
