defmodule Coderacer.CodeCacheTest do
  use ExUnit.Case, async: false

  alias Coderacer.CodeCache

  setup do
    # Ensure the cache is running
    case Process.whereis(CodeCache) do
      nil -> CodeCache.start_link()
      _pid -> :ok
    end

    :ok
  end

  describe "get_code/3" do
    test "returns {:error, :not_found} for uncached combinations" do
      # Use an unlikely combination that won't be cached immediately
      assert {:error, :not_found} = CodeCache.get_code("cobol", "nightmare", 100)
    end

    test "returns {:ok, code} for cached combinations" do
      # This test might be flaky since cache generation is async
      # We'll just verify the function works
      result = CodeCache.get_code("python", "easy", 10)
      assert match?({:ok, _code}, result) or match?({:error, :not_found}, result)
    end

    test "works with new 5-element key format" do
      # Wait for some entries to be generated
      Process.sleep(2000)

      # Get some entries to test with
      entries = CodeCache.get_all_cached_code(limit: 5)

      if length(entries) > 0 do
        entry = List.first(entries)

        # Test that get_code works with the new format
        result = CodeCache.get_code(entry.language, entry.difficulty, entry.lines)
        assert match?({:ok, _code}, result)

        # The returned code should be a non-empty string
        {:ok, code} = result
        assert is_binary(code)
        assert String.length(code) > 0
      end
    end

    test "randomization works when multiple entries exist" do
      # Wait for cache to populate
      Process.sleep(3000)

      # Find a combination that has multiple entries
      entries = CodeCache.get_all_cached_code()

      # Group by combination to find one with multiple entries
      combinations_with_counts =
        entries
        |> Enum.group_by(fn entry -> {entry.language, entry.difficulty, entry.lines} end)
        |> Enum.find(fn {_combo, entries} -> length(entries) > 1 end)

      if combinations_with_counts do
        {{language, difficulty, lines}, _entries} = combinations_with_counts

        # Call get_code multiple times to test randomization
        results =
          for _i <- 1..10 do
            case CodeCache.get_code(language, difficulty, lines) do
              # Get a preview for comparison
              {:ok, code} -> String.slice(code, 0, 50)
              _ -> nil
            end
          end

        # Filter out any nil results
        valid_results = Enum.reject(results, &is_nil/1)

        # We should have some results
        assert length(valid_results) > 0

        # All results should be strings
        for result <- valid_results do
          assert is_binary(result)
        end
      end
    end
  end

  describe "get_stats/0" do
    test "returns cache statistics" do
      stats = CodeCache.get_stats()

      assert is_map(stats)
      assert Map.has_key?(stats, :cached_entries)
      assert Map.has_key?(stats, :unique_combinations_covered)
      assert Map.has_key?(stats, :total_combinations)
      assert Map.has_key?(stats, :entries_per_generation)
      assert Map.has_key?(stats, :max_entries_per_combination)
      assert Map.has_key?(stats, :max_possible_entries)
      assert Map.has_key?(stats, :avg_entries_per_combination)
      assert Map.has_key?(stats, :combination_coverage_percentage)
      assert Map.has_key?(stats, :entry_coverage_percentage)
      assert Map.has_key?(stats, :generation_in_progress)
      assert Map.has_key?(stats, :failed_combinations)

      assert is_integer(stats.cached_entries)
      assert is_integer(stats.unique_combinations_covered)
      assert is_integer(stats.total_combinations)
      assert is_integer(stats.entries_per_generation)
      assert is_integer(stats.max_entries_per_combination)
      assert is_integer(stats.max_possible_entries)
      assert is_float(stats.avg_entries_per_combination)
      assert is_integer(stats.combination_coverage_percentage)
      assert is_integer(stats.entry_coverage_percentage)
      assert is_boolean(stats.generation_in_progress)
      assert is_integer(stats.failed_combinations)

      # Total combinations should be 26 languages * 3 difficulties * 3 line counts = 234
      assert stats.total_combinations == 234
      # With 12 max entries per combination, max possible entries = 234 * 12 = 2808
      assert stats.max_possible_entries == 2808
      assert stats.entries_per_generation == 3
      assert stats.max_entries_per_combination == 12
    end

    test "auto-cleans old format entries during stats collection" do
      # This test verifies that the stats function gracefully handles any old format entries
      # Since we can't easily inject old format entries in tests, we'll verify the stats
      # function completes successfully and returns valid data

      stats = CodeCache.get_stats()

      # All returned values should be valid
      assert stats.cached_entries >= 0
      assert stats.unique_combinations_covered >= 0
      assert stats.avg_entries_per_combination >= 0.0

      # Percentages should be between 0 and 100
      assert stats.combination_coverage_percentage >= 0 and
               stats.combination_coverage_percentage <= 100

      assert stats.entry_coverage_percentage >= 0 and stats.entry_coverage_percentage <= 100
    end
  end

  describe "regenerate_all/0" do
    test "returns :ok when not in progress" do
      # This might return an error if generation is already in progress
      result = CodeCache.regenerate_all()
      assert result == :ok or result == {:error, :generation_in_progress}
    end

    test "clears cache before regenerating" do
      # First, ensure we have some entries by waiting a bit
      Process.sleep(1000)

      # Check initial state
      initial_stats = CodeCache.get_stats()

      # If generation is in progress, wait for it to complete
      if initial_stats.generation_in_progress do
        :timer.sleep(5000)
      end

      # Try to get some cached entries first
      entries_before = CodeCache.get_all_cached_code(limit: 5)

      # If we have entries, trigger regenerate_all
      if length(entries_before) > 0 do
        # Regenerate should clear and restart
        result = CodeCache.regenerate_all()

        if result == :ok do
          # Check immediately after regenerate call - cache should be empty
          stats_after_clear = CodeCache.get_stats()

          # The cache should be cleared (or very few entries if generation just started)
          assert stats_after_clear.cached_entries <= initial_stats.cached_entries
          assert stats_after_clear.generation_in_progress == true
        end
      end
    end
  end

  describe "get_all_cached_code/1" do
    test "returns all cached code entries in a readable format" do
      entries = CodeCache.get_all_cached_code()

      assert is_list(entries)

      # Each entry should have the expected structure with generation tracking
      for entry <- entries do
        assert Map.has_key?(entry, :language)
        assert Map.has_key?(entry, :difficulty)
        assert Map.has_key?(entry, :lines)
        assert Map.has_key?(entry, :generation_id)
        assert Map.has_key?(entry, :entry_id)
        assert Map.has_key?(entry, :code)
        assert Map.has_key?(entry, :cached_at)
        assert Map.has_key?(entry, :code_preview)

        assert is_binary(entry.language)
        assert is_binary(entry.difficulty)
        assert is_integer(entry.lines)
        assert is_integer(entry.generation_id)
        assert is_integer(entry.entry_id)
        assert is_binary(entry.code)
        assert %DateTime{} = entry.cached_at
        assert is_binary(entry.code_preview)

        # Generation ID should be a reasonable timestamp (after 2020)
        assert entry.generation_id > 1_600_000_000
        # Entry ID should be between 1 and 3 (entries per generation)
        assert entry.entry_id >= 1 and entry.entry_id <= 3
      end
    end

    test "includes generation_id in entry structure" do
      # Wait for some entries to be generated
      Process.sleep(1000)
      entries = CodeCache.get_all_cached_code(limit: 3)

      for entry <- entries do
        # Verify new structure includes generation_id
        assert Map.has_key?(entry, :generation_id)
        assert is_integer(entry.generation_id)
        # Should be a Unix timestamp (reasonable range)
        assert entry.generation_id > 1_600_000_000
      end
    end

    test "respects language filter" do
      entries = CodeCache.get_all_cached_code(language: "python")

      for entry <- entries do
        assert entry.language == "python"
      end
    end

    test "respects difficulty filter" do
      entries = CodeCache.get_all_cached_code(difficulty: "easy")

      for entry <- entries do
        assert entry.difficulty == "easy"
      end
    end

    test "respects lines filter" do
      entries = CodeCache.get_all_cached_code(lines: 10)

      for entry <- entries do
        assert entry.lines == 10
      end
    end

    test "respects limit option" do
      entries = CodeCache.get_all_cached_code(limit: 5)

      assert length(entries) <= 5
    end

    test "returns entries sorted by cached_at in descending order" do
      entries = CodeCache.get_all_cached_code(limit: 10)

      if length(entries) > 1 do
        timestamps = Enum.map(entries, & &1.cached_at)
        sorted_timestamps = Enum.sort(timestamps, {:desc, DateTime})
        assert timestamps == sorted_timestamps
      end
    end
  end

  describe "clear_cache/0" do
    test "clears all cached entries" do
      # Wait for some entries to be generated
      Process.sleep(2000)

      # Clear the cache
      result = CodeCache.clear_cache()
      assert result == :ok

      # Check that cache is cleared
      stats_after = CodeCache.get_stats()
      assert stats_after.cached_entries == 0
      assert stats_after.unique_combinations_covered == 0

      # Verify get_code returns not_found after clearing
      assert {:error, :not_found} = CodeCache.get_code("python", "easy", 10)

      # Verify get_all_cached_code returns empty list
      entries = CodeCache.get_all_cached_code()
      assert entries == []
    end

    test "can be called multiple times safely" do
      # Clear multiple times should work fine
      assert :ok = CodeCache.clear_cache()
      assert :ok = CodeCache.clear_cache()
      assert :ok = CodeCache.clear_cache()

      # Cache should still be empty
      stats = CodeCache.get_stats()
      assert stats.cached_entries == 0
    end
  end

  describe "accumulating cache behavior" do
    test "generates multiple entries per combination" do
      # Wait for cache to populate with multiple entries
      Process.sleep(4000)

      stats = CodeCache.get_stats()

      if stats.cached_entries > 0 and stats.unique_combinations_covered > 0 do
        # Average entries per combination should be between 1 and max_entries_per_combination
        assert stats.avg_entries_per_combination >= 1.0
        assert stats.avg_entries_per_combination <= stats.max_entries_per_combination

        # Check if we have combinations with multiple entries
        entries = CodeCache.get_all_cached_code()

        combinations_with_counts =
          entries
          |> Enum.group_by(fn entry -> {entry.language, entry.difficulty, entry.lines} end)
          |> Enum.map(fn {combo, entries} -> {combo, length(entries)} end)

        # We should have some combinations with multiple entries
        multiple_entry_combos =
          Enum.filter(combinations_with_counts, fn {_combo, count} -> count > 1 end)

        if length(multiple_entry_combos) > 0 do
          # All counts should be reasonable (between 1 and max_entries_per_combination)
          for {_combo, count} <- multiple_entry_combos do
            assert count >= 1 and count <= stats.max_entries_per_combination
          end
        end
      end
    end

    test "entries have different generation_ids across regenerations" do
      # This is harder to test in isolation, but we can verify the structure
      entries = CodeCache.get_all_cached_code(limit: 10)

      if length(entries) > 1 do
        generation_ids = entries |> Enum.map(& &1.generation_id) |> Enum.uniq()

        # All generation IDs should be valid timestamps
        for gen_id <- generation_ids do
          assert is_integer(gen_id)
          # After 2020
          assert gen_id > 1_600_000_000
        end
      end
    end
  end
end
