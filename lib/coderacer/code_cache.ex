defmodule Coderacer.CodeCache do
  @moduledoc """
  A resilient ETS-based cache for storing generated code snippets with accumulating variety.

  This GenServer manages the periodic generation and caching of code snippets for all
  supported language/difficulty/lines combinations. The cache uses a "Quality-Capped
  Accumulation" strategy with self-healing capabilities.

  ## Accumulation Strategy
  - **Initial Generation**: Creates 3 entries per combination
  - **Regeneration Cycles**: Adds 3 new entries every 3 hours (doesn't replace)
  - **Quality Cap**: Maximum 12 entries per combination
  - **Pruning**: When cap reached, removes oldest entries first
  - **Selection**: Random selection from all available entries across generations

  ## Resilience & Simplicity
  - **No Backward Compatibility**: Uses only the current key format
  - **Self-Healing**: Can clear and regenerate entire cache when needed
  - **Fresh Start**: `regenerate_all/0` clears cache before regenerating
  - **Manual Recovery**: `clear_cache/0` for troubleshooting

  ## Storage Format
  Each entry uses a 5-element key: `{language, difficulty, lines, generation_id, entry_id}`

  ## Features
  - Periodic regeneration every 3 hours with cache clearing
  - Automatic retry on failures with 30-minute intervals
  - Growing variety pool (3→6→9→12 entries per combination)
  - Bounded memory usage with intelligent pruning
  - Real-time statistics and monitoring
  - Cache clearing capabilities for resilience

  ## Total Capacity
  - 234 combinations (26 languages × 3 difficulties × 3 line counts)
  - Up to 2,808 total entries at full capacity (234 × 12)
  - Estimated 7-35 MB memory usage when fully populated

  The cache provides immediate fallback to live generation if entries are not found.
  If anything goes wrong, simply clear the cache and regenerate fresh!
  """
  use GenServer
  require Logger

  @table_name :code_cache
  @default_interval :timer.hours(12)
  @retry_interval :timer.minutes(30)
  @default_lines [10, 15, 20]
  # New entries added per generation
  @entries_per_combination 3
  # Maximum entries before pruning oldest
  @max_entries_per_combination 12
  # Note: Maximum generations = @max_entries_per_combination / @entries_per_combination = 4

  # Languages from StartLive
  @languages [
    "c",
    "clojure",
    "cpp",
    "csharp",
    "css",
    "dart",
    "elixir",
    "go",
    "haskell",
    "html",
    "java",
    "javascript",
    "kotlin",
    "matlab",
    "objectivec",
    "perl",
    "php",
    "python",
    "r",
    "ruby",
    "rust",
    "scala",
    "shell",
    "sql",
    "swift",
    "typescript"
  ]

  # Difficulties from StartLive
  @difficulties ["easy", "medium", "hard"]

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets cached code for the given language, difficulty, and lines.
  Randomly selects from available entries across all generations.
  Returns {:ok, code} or {:error, :not_found}.
  """
  def get_code(language, difficulty, lines \\ 10) do
    # Use new format only: {language, difficulty, lines, generation_id, entry_id}
    pattern = {{language, difficulty, lines, :"$1", :"$2"}, :"$3"}

    case :ets.match(@table_name, pattern) do
      [] ->
        {:error, :not_found}

      matches ->
        # Extract code from matches: [[gen_id, entry_id, {code, timestamp}], ...]
        entries = for [_gen_id, _entry_id, {code, _timestamp}] <- matches, do: code
        # Randomly select one entry from all available entries
        selected_code = Enum.random(entries)
        {:ok, selected_code}
    end
  end

  @doc """
  Clears all cached entries. Useful for troubleshooting or forced refresh.
  """
  def clear_cache do
    GenServer.call(__MODULE__, :clear_cache)
  end

  @doc """
  Forces regeneration of all cached code.
  Clears the existing cache and starts fresh generation.
  """
  def regenerate_all do
    GenServer.call(__MODULE__, :regenerate_all, :timer.minutes(10))
  end

  @doc """
  Gets all cached code entries.
  Returns a list of maps with metadata and code.

  Options:
  - `:language` - Filter by specific language
  - `:difficulty` - Filter by specific difficulty
  - `:lines` - Filter by specific line count
  - `:limit` - Limit number of results (default: 50)
  """
  def get_all_cached_code(opts \\ []) do
    language_filter = Keyword.get(opts, :language)
    difficulty_filter = Keyword.get(opts, :difficulty)
    lines_filter = Keyword.get(opts, :lines)
    limit = Keyword.get(opts, :limit, 50)

    @table_name
    |> :ets.tab2list()
    |> Enum.filter(fn
      # New format only: {language, difficulty, lines, generation_id, entry_id}
      {{lang, diff, lines, _gen_id, _entry_id}, _} ->
        (is_nil(language_filter) or lang == language_filter) and
          (is_nil(difficulty_filter) or diff == difficulty_filter) and
          (is_nil(lines_filter) or lines == lines_filter)
    end)
    |> Enum.take(limit)
    |> Enum.map(fn
      {{language, difficulty, lines, generation_id, entry_id}, {code, timestamp}} ->
        %{
          language: language,
          difficulty: difficulty,
          lines: lines,
          generation_id: generation_id,
          entry_id: entry_id,
          code: code,
          cached_at: timestamp,
          code_preview:
            String.slice(code, 0, 100) <> if(String.length(code) > 100, do: "...", else: "")
        }
    end)
    |> Enum.sort_by(& &1.cached_at, {:desc, DateTime})
  end

  @doc """
  Gets cache statistics.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  ## Server Callbacks

  @impl true
  def init(opts) do
    interval = Keyword.get(opts, :interval, @default_interval)
    lines_options = Keyword.get(opts, :lines, @default_lines)

    # Create ETS table
    :ets.new(@table_name, [:named_table, :public, read_concurrency: true])

    # Schedule initial generation
    send(self(), :generate_all)

    # Schedule periodic generation
    Process.send_after(self(), :generate_all, interval)

    state = %{
      interval: interval,
      lines_options: lines_options,
      generation_in_progress: false,
      last_generation: nil,
      failed_combinations: []
    }

    Logger.info(
      "CodeCache started with #{length(@languages)} languages, #{length(@difficulties)} difficulties, #{length(lines_options)} line options"
    )

    {:ok, state}
  end

  @impl true
  def handle_call(:clear_cache, _from, state) do
    :ets.delete_all_objects(@table_name)
    Logger.info("Cache cleared manually")
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:regenerate_all, _from, state) do
    if state.generation_in_progress do
      {:reply, {:error, :generation_in_progress}, state}
    else
      # Clear the entire ETS table for fresh start
      :ets.delete_all_objects(@table_name)
      Logger.info("Cleared ETS cache for fresh regeneration")

      send(self(), :generate_all)
      {:reply, :ok, state}
    end
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    total_combinations = length(@languages) * length(@difficulties) * length(state.lines_options)
    max_possible_entries = total_combinations * @max_entries_per_combination

    # Calculate unique combinations covered, handling any old format entries
    all_entries = :ets.tab2list(@table_name)

    {valid_entries, invalid_entries} =
      Enum.split_with(all_entries, fn
        {{_lang, _diff, _lines, _gen_id, _entry_id}, _} -> true
        _ -> false
      end)

    # Clean up any invalid (old format) entries
    if length(invalid_entries) > 0 do
      Logger.info("Cleaning up #{length(invalid_entries)} old format entries")

      for {key, _} <- invalid_entries do
        :ets.delete(@table_name, key)
      end
    end

    # Recalculate with clean data
    unique_combinations =
      valid_entries
      |> Enum.map(fn {{lang, diff, lines, _gen_id, _entry_id}, _} -> {lang, diff, lines} end)
      |> Enum.uniq()
      |> length()

    current_cache_size = length(valid_entries)

    # Calculate average entries per combination for covered combinations
    avg_entries_per_combination =
      if unique_combinations > 0 do
        Float.round(current_cache_size / unique_combinations, 1)
      else
        0.0
      end

    stats = %{
      cached_entries: current_cache_size,
      unique_combinations_covered: unique_combinations,
      total_combinations: total_combinations,
      entries_per_generation: @entries_per_combination,
      max_entries_per_combination: @max_entries_per_combination,
      max_possible_entries: max_possible_entries,
      avg_entries_per_combination: avg_entries_per_combination,
      combination_coverage_percentage:
        if(total_combinations > 0,
          do: round(unique_combinations / total_combinations * 100),
          else: 0
        ),
      entry_coverage_percentage:
        if(max_possible_entries > 0,
          do: round(current_cache_size / max_possible_entries * 100),
          else: 0
        ),
      last_generation: state.last_generation,
      failed_combinations: length(state.failed_combinations),
      generation_in_progress: state.generation_in_progress
    }

    {:reply, stats, state}
  end

  @impl true
  def handle_info(:generate_all, state) do
    if state.generation_in_progress do
      Logger.warning("Skipping code generation - already in progress")
      schedule_next_generation(state.interval)
      {:noreply, state}
    else
      Logger.info("Starting code generation for all combinations")

      new_state = %{state | generation_in_progress: true, failed_combinations: []}

      # Generate in background to avoid blocking
      Task.start(fn -> generate_all_combinations(state.lines_options) end)

      {:noreply, new_state}
    end
  end

  @impl true
  def handle_info(:generation_complete, state) do
    Logger.info("Code generation completed")

    new_state = %{state | generation_in_progress: false, last_generation: DateTime.utc_now()}

    # Schedule next generation
    schedule_next_generation(state.interval)

    # Retry failed combinations after delay
    if length(state.failed_combinations) > 0 do
      Logger.info("Scheduling retry for #{length(state.failed_combinations)} failed combinations")
      Process.send_after(self(), {:retry_failed, state.failed_combinations}, @retry_interval)
    end

    {:noreply, new_state}
  end

  @impl true
  def handle_info({:retry_failed, combinations}, state) do
    Logger.info("Retrying #{length(combinations)} failed combinations")

    Task.start(fn ->
      retry_combinations(combinations)
      send(__MODULE__, :retry_complete)
    end)

    {:noreply, state}
  end

  @impl true
  def handle_info(:retry_complete, state) do
    Logger.info("Retry generation completed")
    {:noreply, state}
  end

  @impl true
  def handle_info({:generation_failed, failed_key}, state) do
    # Extract the base combination from the failed key
    {language, difficulty, lines, _gen_id, _entry_id} = failed_key
    base_combination = {language, difficulty, lines}

    updated_failed = [base_combination | state.failed_combinations] |> Enum.uniq()

    Logger.warning("Generation failed for #{language}/#{difficulty}/#{lines}")

    # Schedule retry for this specific combination in 30 minutes
    schedule_retry(base_combination)

    {:noreply, %{state | failed_combinations: updated_failed}}
  end

  ## Private Functions

  defp generate_all_combinations(lines_options) do
    combinations =
      for language <- @languages,
          difficulty <- @difficulties,
          lines <- lines_options,
          entry_num <- 1..@entries_per_combination,
          do: {language, difficulty, lines, entry_num}

    total = length(combinations)

    Logger.info(
      "Generating code for #{total} entries (#{@entries_per_combination} per combination)"
    )

    # Process in batches to avoid overwhelming the API
    combinations
    |> Enum.chunk_every(5)
    |> Enum.with_index()
    |> Enum.each(fn {batch, batch_index} ->
      Enum.each(batch, fn combination ->
        generate_and_cache(combination)
        # Small delay between requests
        Process.sleep(1000)
      end)

      Logger.info("Completed batch #{batch_index + 1}/#{div(total, 5) + 1}")

      # Longer delay between batches
      if batch_index < div(total, 5) do
        Process.sleep(5000)
      end
    end)

    send(__MODULE__, :generation_complete)
  end

  defp retry_combinations(combinations) do
    Enum.each(combinations, fn combination ->
      generate_and_cache(combination)
      Process.sleep(2000)
    end)
  end

  defp generate_and_cache({language, difficulty, lines, entry_num}) do
    case Coderacer.AI.generate_live(language, difficulty, lines) do
      {:ok, code} ->
        timestamp = DateTime.utc_now()
        generation_id = System.system_time(:second)
        key = {language, difficulty, lines, generation_id, entry_num}

        # Insert new entry
        :ets.insert(@table_name, {key, {code, timestamp}})

        # Check if we need to prune old entries for this combination
        prune_old_entries_if_needed(language, difficulty, lines)

        Logger.debug(
          "Cached code entry #{entry_num} for #{language}/#{difficulty}/#{lines} lines (generation #{generation_id})"
        )

      {:error, _status, reason} ->
        generation_id = System.system_time(:second)

        Logger.error(
          "Failed to generate code entry #{entry_num} for #{language}/#{difficulty}/#{lines}: #{inspect(reason)}"
        )

        send(
          __MODULE__,
          {:generation_failed, {language, difficulty, lines, generation_id, entry_num}}
        )
    end
  end

  defp prune_old_entries_if_needed(language, difficulty, lines) do
    # Find all entries for this combination
    pattern = {{language, difficulty, lines, :_, :_}, :_}

    case :ets.match(@table_name, pattern) do
      entries when length(entries) > @max_entries_per_combination ->
        # Get full entries with keys for sorting
        all_entries =
          :ets.tab2list(@table_name)
          |> Enum.filter(fn {{lang, diff, l, _gen, _entry}, _} ->
            lang == language and diff == difficulty and l == lines
          end)

        # Sort by generation_id (older first) then by timestamp
        sorted_entries =
          all_entries
          |> Enum.sort_by(fn {{_lang, _diff, _lines, gen_id, _entry}, {_code, timestamp}} ->
            {gen_id, timestamp}
          end)

        # Calculate how many to remove
        excess_count = length(sorted_entries) - @max_entries_per_combination
        entries_to_remove = Enum.take(sorted_entries, excess_count)

        # Remove the oldest entries
        for {key_to_remove, _} <- entries_to_remove do
          :ets.delete(@table_name, key_to_remove)
        end

        if excess_count > 0 do
          Logger.info("Pruned #{excess_count} old entries for #{language}/#{difficulty}/#{lines}")
        end

      _ ->
        :ok
    end
  end

  defp schedule_next_generation(interval) do
    Process.send_after(self(), :generate_all, interval)
  end

  defp schedule_retry({language, difficulty, lines}) do
    # Create entries for retry with current generation timestamp
    retry_tasks =
      for entry_num <- 1..@entries_per_combination do
        {language, difficulty, lines, entry_num}
      end

    Process.send_after(self(), {:retry_failed, retry_tasks}, @retry_interval)
  end
end
