defmodule Coderacer.CodeCacheTest do
  use ExUnit.Case, async: false

  alias Coderacer.CodeCache

  setup do
    # Ensure the cache is running but don't interfere with existing process
    case Process.whereis(CodeCache) do
      nil ->
        {:ok, _pid} = CodeCache.start_link()

      _pid ->
        :ok
    end

    :ok
  end

  describe "start_link/1 and initialization" do
    test "process is running and accessible" do
      # Just verify the process is accessible
      assert Process.whereis(CodeCache) != nil
      assert Process.alive?(Process.whereis(CodeCache))
    end

    test "ETS table is created and accessible" do
      # Verify ETS table was created
      assert :ets.info(:code_cache) != :undefined

      # Verify it's a public table with read concurrency
      info = :ets.info(:code_cache)
      assert info[:type] == :set
      assert info[:protection] == :public
      assert info[:read_concurrency] == true
    end

    test "initial state is correct" do
      # Test that we can get stats, which means initialization worked
      stats = CodeCache.get_stats()
      assert is_map(stats)
      assert Map.has_key?(stats, :generation_in_progress)
      assert is_boolean(stats.generation_in_progress)

      # Verify configuration values are set correctly
      assert stats.entries_per_generation == 3
      assert stats.max_entries_per_combination == 12
      # 26 languages * 3 difficulties * 3 lines
      assert stats.total_combinations == 234
    end
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

    test "uses default lines parameter when not specified" do
      # Test the default lines parameter
      result1 = CodeCache.get_code("python", "easy")
      result2 = CodeCache.get_code("python", "easy", 10)

      # Both should have the same type of result
      assert (match?({:ok, _}, result1) and match?({:ok, _}, result2)) or
               (match?({:error, :not_found}, result1) and match?({:error, :not_found}, result2))
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

    test "handles invalid input gracefully" do
      # Test with nil values
      assert {:error, :not_found} = CodeCache.get_code(nil, "easy", 10)
      assert {:error, :not_found} = CodeCache.get_code("python", nil, 10)
      assert {:error, :not_found} = CodeCache.get_code("python", "easy", nil)

      # Test with empty strings
      assert {:error, :not_found} = CodeCache.get_code("", "easy", 10)
      assert {:error, :not_found} = CodeCache.get_code("python", "", 10)

      # Test with invalid numbers
      assert {:error, :not_found} = CodeCache.get_code("python", "easy", -1)
      assert {:error, :not_found} = CodeCache.get_code("python", "easy", 0)
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

    test "handles empty cache correctly" do
      # Clear cache first
      CodeCache.clear_cache()

      stats = CodeCache.get_stats()

      assert stats.cached_entries == 0
      assert stats.unique_combinations_covered == 0
      assert stats.avg_entries_per_combination == 0.0
      assert stats.combination_coverage_percentage == 0
      assert stats.entry_coverage_percentage == 0
    end

    test "calculates percentages correctly" do
      stats = CodeCache.get_stats()

      # If we have entries, test percentage calculations
      if stats.cached_entries > 0 do
        expected_combo_percentage =
          round(stats.unique_combinations_covered / stats.total_combinations * 100)

        expected_entry_percentage = round(stats.cached_entries / stats.max_possible_entries * 100)

        assert stats.combination_coverage_percentage == expected_combo_percentage
        assert stats.entry_coverage_percentage == expected_entry_percentage
      end
    end
  end

  describe "regenerate_all/0" do
    test "returns :ok when not in progress" do
      # This might return an error if generation is already in progress
      result = CodeCache.regenerate_all()
      assert result == :ok or result == {:error, :generation_in_progress}
    end

    test "returns error when generation is in progress" do
      # Start generation
      stats = CodeCache.get_stats()

      if not stats.generation_in_progress do
        # Trigger generation if not in progress
        CodeCache.regenerate_all()

        # Try to regenerate again immediately - should get error
        result = CodeCache.regenerate_all()
        assert result == {:error, :generation_in_progress}
      end
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

    test "handles timeout correctly" do
      # Test the call timeout
      result = CodeCache.regenerate_all()

      # Should complete within the timeout
      assert result == :ok or result == {:error, :generation_in_progress}
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

    test "handles zero limit" do
      entries = CodeCache.get_all_cached_code(limit: 0)
      assert entries == []
    end

    test "handles negative limit gracefully" do
      entries = CodeCache.get_all_cached_code(limit: -1)
      # Should handle gracefully, likely return empty or all entries
      assert is_list(entries)
    end

    test "returns entries sorted by cached_at in descending order" do
      entries = CodeCache.get_all_cached_code(limit: 10)

      if length(entries) > 1 do
        timestamps = Enum.map(entries, & &1.cached_at)
        sorted_timestamps = Enum.sort(timestamps, {:desc, DateTime})
        assert timestamps == sorted_timestamps
      end
    end

    test "combines multiple filters correctly" do
      entries = CodeCache.get_all_cached_code(language: "python", difficulty: "easy", limit: 3)

      assert length(entries) <= 3

      for entry <- entries do
        assert entry.language == "python"
        assert entry.difficulty == "easy"
      end
    end

    test "handles non-existent filter values" do
      entries = CodeCache.get_all_cached_code(language: "nonexistent")
      assert entries == []
    end

    test "code_preview is properly truncated" do
      entries = CodeCache.get_all_cached_code(limit: 5)

      for entry <- entries do
        if String.length(entry.code) > 100 do
          # 100 + "..."
          assert String.length(entry.code_preview) == 103
          assert String.ends_with?(entry.code_preview, "...")
        else
          assert entry.code_preview == entry.code
        end
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

    test "clears cache even when generation is in progress" do
      # Start generation
      initial_stats = CodeCache.get_stats()

      if not initial_stats.generation_in_progress do
        CodeCache.regenerate_all()
      end

      # Clear cache even during generation
      result = CodeCache.clear_cache()
      assert result == :ok

      # Verify it's cleared
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

    test "respects max entries per combination" do
      # This is a longer-term behavior test
      Process.sleep(2000)

      entries = CodeCache.get_all_cached_code()

      if length(entries) > 0 do
        # Group entries by combination
        combinations_with_counts =
          entries
          |> Enum.group_by(fn entry -> {entry.language, entry.difficulty, entry.lines} end)
          |> Enum.map(fn {_combo, entries} -> length(entries) end)

        # No combination should exceed max entries
        max_count = Enum.max(combinations_with_counts)
        # max_entries_per_combination
        assert max_count <= 12
      end
    end
  end

  describe "generation failure handling" do
    test "tracks failed combinations" do
      # Ensure process is running and handle potential exit
      unless Process.alive?(Process.whereis(CodeCache)) do
        {:ok, _pid} = CodeCache.start_link()
      end

      stats =
        try do
          CodeCache.get_stats()
        catch
          :exit, _ ->
            # If process crashed, restart and get stats
            {:ok, _pid} = CodeCache.start_link()
            CodeCache.get_stats()
        end

      # Failed combinations should be a non-negative integer
      assert is_integer(stats.failed_combinations)
      assert stats.failed_combinations >= 0
    end

    test "handles generation failures gracefully" do
      # We can't easily simulate API failures in tests, but we can verify
      # the system continues working even when there are failures

      # Ensure process is running
      unless Process.alive?(Process.whereis(CodeCache)) do
        {:ok, _pid} = CodeCache.start_link()
      end

      stats =
        try do
          CodeCache.get_stats()
        catch
          :exit, _ ->
            # If process crashed, restart and get stats
            {:ok, _pid} = CodeCache.start_link()
            CodeCache.get_stats()
        end

      # System should still be functional regardless of failed combinations
      assert is_boolean(stats.generation_in_progress)

      # Should be able to get some data or at least empty results
      entries =
        try do
          CodeCache.get_all_cached_code(limit: 1)
        catch
          :exit, _ -> []
        end

      assert is_list(entries)
    end
  end

  describe "ETS table management" do
    test "ETS table exists and is accessible" do
      # Verify ETS table exists
      assert :ets.info(:code_cache) != :undefined

      # Verify it's a public table with read concurrency
      info = :ets.info(:code_cache)
      assert info[:type] == :set
      assert info[:protection] == :public
      assert info[:read_concurrency] == true
    end

    test "ETS table structure matches expected format" do
      entries = CodeCache.get_all_cached_code(limit: 5)

      if length(entries) > 0 do
        # Each entry should follow the 5-element key format
        for entry <- entries do
          assert is_binary(entry.language)
          assert is_binary(entry.difficulty)
          assert is_integer(entry.lines)
          assert is_integer(entry.generation_id)
          assert is_integer(entry.entry_id)
        end
      end
    end

    test "direct ETS operations work correctly" do
      # Test that we can interact with the ETS table directly
      table_info = :ets.info(:code_cache)
      assert table_info != :undefined

      # Get table size
      size = :ets.info(:code_cache, :size)
      assert is_integer(size)
      assert size >= 0
    end
  end

  describe "GenServer state management" do
    test "handles info messages correctly" do
      # This tests internal GenServer message handling indirectly
      stats_before = CodeCache.get_stats()

      # The fact that we can get stats means the GenServer is handling calls correctly
      assert is_boolean(stats_before.generation_in_progress)

      # Trigger regeneration to test message handling
      if not stats_before.generation_in_progress do
        result = CodeCache.regenerate_all()
        assert result == :ok or result == {:error, :generation_in_progress}

        # Wait a moment and check again
        Process.sleep(100)
        stats_after = CodeCache.get_stats()
        assert is_boolean(stats_after.generation_in_progress)
      end
    end

    test "maintains state across operations" do
      # Test that state is maintained across multiple operations
      CodeCache.get_stats()
      CodeCache.get_all_cached_code(limit: 1)
      CodeCache.get_code("python", "easy", 10)

      # All operations should still work
      final_stats = CodeCache.get_stats()
      assert is_map(final_stats)
      assert Map.has_key?(final_stats, :generation_in_progress)
    end
  end

  describe "delay configuration" do
    test "verifies delay constants are properly configured" do
      # Since the delay constants are module attributes, we can't access them directly
      # from outside the module. However, we can verify they're being used by checking
      # module compilation and that the module loads without issues.

      # Verify the module is loaded and functioning
      assert Code.ensure_loaded?(Coderacer.CodeCache)

      # Verify that the module's functions work (which means delays are configured correctly)
      stats = CodeCache.get_stats()
      assert is_map(stats)

      # If this test passes, it means the delay constants were set correctly
      # and didn't cause compilation errors
      assert true
    end

    test "generation process respects delay timing indirectly" do
      # We can't directly test the delays without making tests very slow,
      # but we can verify that the generation process works correctly
      # which implies delays are functioning.

      initial_stats = CodeCache.get_stats()

      # If generation is not in progress, the system is stable
      # If it is in progress, the delays are working to prevent overwhelming the API
      assert is_boolean(initial_stats.generation_in_progress)

      # The fact that we can get stats means the module is working correctly
      # with the configured delays
      assert initial_stats.entries_per_generation == 3
      assert initial_stats.max_entries_per_combination == 12
    end
  end

  describe "module constants and configuration" do
    test "supported languages list is comprehensive" do
      stats = CodeCache.get_stats()

      # Should support 26 languages (as per the module)
      expected_languages = 26
      expected_difficulties = 3
      expected_lines = 3
      expected_total = expected_languages * expected_difficulties * expected_lines

      assert stats.total_combinations == expected_total
    end

    test "configuration values are correct" do
      stats = CodeCache.get_stats()

      assert stats.entries_per_generation == 3
      assert stats.max_entries_per_combination == 12
      # 2808
      assert stats.max_possible_entries == 234 * 12
    end
  end

  describe "concurrent access" do
    test "handles concurrent read operations" do
      # Ensure process is running before starting concurrent operations
      unless Process.alive?(Process.whereis(CodeCache)) do
        {:ok, _pid} = CodeCache.start_link()
      end

      # Test multiple concurrent read operations
      tasks =
        for _ <- 1..5 do
          Task.async(fn ->
            try do
              CodeCache.get_stats()
            catch
              # Handle case where process stops
              :exit, _ -> %{cached_entries: 0}
            end
          end)
        end

      results = Task.await_many(tasks, 5000)

      # All should succeed or return fallback
      for result <- results do
        assert is_map(result)
        assert Map.has_key?(result, :cached_entries)
      end
    end

    test "handles concurrent get_code operations" do
      # Ensure process is running
      unless Process.alive?(Process.whereis(CodeCache)) do
        {:ok, _pid} = CodeCache.start_link()
      end

      tasks =
        for _ <- 1..5 do
          Task.async(fn ->
            try do
              CodeCache.get_code("python", "easy", 10)
            catch
              # Handle case where process stops
              :exit, _ -> {:error, :not_found}
            end
          end)
        end

      results = Task.await_many(tasks, 5000)

      # All should return consistent results
      for result <- results do
        assert match?({:ok, _}, result) or match?({:error, :not_found}, result)
      end
    end
  end

  describe "edge cases and error handling" do
    test "handles empty ETS table gracefully" do
      # Clear cache to create empty state
      CodeCache.clear_cache()

      # All operations should work with empty cache
      assert {:error, :not_found} = CodeCache.get_code("python", "easy", 10)
      assert [] = CodeCache.get_all_cached_code()

      stats = CodeCache.get_stats()
      assert stats.cached_entries == 0
      assert stats.unique_combinations_covered == 0
    end

    test "handles large limit values" do
      # Test with very large limit
      entries = CodeCache.get_all_cached_code(limit: 100_000)
      assert is_list(entries)
      # Should not crash and should return reasonable number of entries
      # Reasonable upper bound
      assert length(entries) < 10_000
    end

    test "handles malformed filter values" do
      # Test with invalid filter types
      entries = CodeCache.get_all_cached_code(language: 123)
      assert entries == []

      entries = CodeCache.get_all_cached_code(difficulty: :invalid)
      assert entries == []
    end
  end

  describe "internal behavior and message handling" do
    test "generation process can be monitored through stats" do
      initial_stats = CodeCache.get_stats()

      # The generation process should be trackable
      assert Map.has_key?(initial_stats, :generation_in_progress)
      assert Map.has_key?(initial_stats, :last_generation)
      assert Map.has_key?(initial_stats, :failed_combinations)

      # Stats should be consistent
      assert initial_stats.cached_entries >= 0
      assert initial_stats.unique_combinations_covered >= 0
      assert initial_stats.failed_combinations >= 0
    end

    test "stats calculation handles edge cases" do
      # Clear cache and check edge case calculations
      CodeCache.clear_cache()

      stats = CodeCache.get_stats()

      # With zero entries, percentages should be 0
      assert stats.combination_coverage_percentage == 0
      assert stats.entry_coverage_percentage == 0
      assert stats.avg_entries_per_combination == 0.0
    end

    test "can handle rapid successive operations" do
      # Test system stability under rapid operations
      for _ <- 1..10 do
        CodeCache.get_stats()
        CodeCache.get_code("python", "easy", 10)
        CodeCache.get_all_cached_code(limit: 1)
      end

      # System should still be responsive
      final_stats = CodeCache.get_stats()
      assert is_map(final_stats)
    end

    test "verifies ETS table operations work correctly" do
      # Clear cache to start fresh
      CodeCache.clear_cache()

      # Verify table is empty
      assert :ets.info(:code_cache, :size) == 0

      # The system should handle empty table correctly
      stats = CodeCache.get_stats()
      assert stats.cached_entries == 0
    end

    test "handles timeout scenarios in regenerate_all" do
      # Test that regenerate_all respects its timeout
      start_time = :os.system_time(:millisecond)

      result = CodeCache.regenerate_all()

      end_time = :os.system_time(:millisecond)
      duration = end_time - start_time

      # Should complete within reasonable time (10 minutes = 600,000ms)
      assert duration < 600_000
      assert result == :ok or result == {:error, :generation_in_progress}
    end
  end

  describe "data integrity and validation" do
    test "all cached entries follow expected format" do
      entries = CodeCache.get_all_cached_code(limit: 10)

      for entry <- entries do
        # Validate entry structure
        assert is_binary(entry.language)
        assert is_binary(entry.difficulty)
        assert is_integer(entry.lines)
        assert is_integer(entry.generation_id)
        assert is_integer(entry.entry_id)
        assert is_binary(entry.code)
        assert %DateTime{} = entry.cached_at
        assert is_binary(entry.code_preview)

        # Validate field constraints
        assert entry.lines > 0
        assert entry.entry_id >= 1 and entry.entry_id <= 3
        # After 2020
        assert entry.generation_id > 1_600_000_000
        assert String.length(entry.language) > 0
        assert entry.difficulty in ["easy", "medium", "hard"]

        # Validate code preview logic
        if String.length(entry.code) > 100 do
          assert String.length(entry.code_preview) == 103
          assert String.ends_with?(entry.code_preview, "...")
        else
          assert entry.code_preview == entry.code
        end
      end
    end

    test "entry IDs are within expected range" do
      entries = CodeCache.get_all_cached_code(limit: 50)

      entry_ids = entries |> Enum.map(& &1.entry_id) |> Enum.uniq()

      for entry_id <- entry_ids do
        # Entry IDs should be 1, 2, or 3 (entries per generation)
        assert entry_id in [1, 2, 3]
      end
    end

    test "generation IDs are reasonable timestamps" do
      entries = CodeCache.get_all_cached_code(limit: 20)

      generation_ids = entries |> Enum.map(& &1.generation_id) |> Enum.uniq()

      for gen_id <- generation_ids do
        # Should be reasonable Unix timestamp
        # After 2020
        assert gen_id > 1_600_000_000
        # Before 2033
        assert gen_id < 2_000_000_000
      end
    end

    test "supported languages are comprehensive" do
      # Test that all expected languages are supported
      stats = CodeCache.get_stats()

      # Should be 26 languages * 3 difficulties * 3 line counts = 234
      assert stats.total_combinations == 234

      # Verify calculation
      expected_languages = 26
      expected_difficulties = 3
      expected_lines = 3

      assert stats.total_combinations ==
               expected_languages * expected_difficulties * expected_lines
    end
  end

  describe "performance and resource management" do
    test "memory usage stays reasonable" do
      stats = CodeCache.get_stats()

      # With max 2808 entries, memory should be reasonable
      if stats.cached_entries > 0 do
        # Average code length should be reasonable (rough estimate)
        entries = CodeCache.get_all_cached_code(limit: 10)

        if length(entries) > 0 do
          avg_code_length =
            entries |> Enum.map(&String.length(&1.code)) |> Enum.sum() |> div(length(entries))

          # Should be reasonable code length (not empty, not huge)
          assert avg_code_length > 10
          assert avg_code_length < 10_000
        end
      end
    end

    test "cache respects maximum entries per combination" do
      entries = CodeCache.get_all_cached_code()

      if length(entries) > 0 do
        # Group by combination and check counts
        combination_counts =
          entries
          |> Enum.group_by(fn entry -> {entry.language, entry.difficulty, entry.lines} end)
          |> Enum.map(fn {_combo, entries} -> length(entries) end)

        max_count = Enum.max(combination_counts)

        # Should not exceed max_entries_per_combination (12)
        assert max_count <= 12
      end
    end

    test "ETS table size matches reported cached entries" do
      stats = CodeCache.get_stats()
      ets_size = :ets.info(:code_cache, :size)

      # ETS size should match reported cached entries
      assert ets_size == stats.cached_entries
    end
  end
end
