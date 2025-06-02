defmodule Coderacer.AI do
  @moduledoc """
  Module documentation for Coderacer.AI.
  """

  def generate(language, difficulty, lines \\ 10) do
    # First try to get from cache
    case Coderacer.CodeCache.get_code(language, difficulty, lines) do
      {:ok, cached_code} ->
        {:ok, cached_code}

      {:error, :not_found} ->
        # Fallback to live generation if not in cache
        generate_live(language, difficulty, lines)
    end
  end

  def generate_live(language, difficulty, lines \\ 10) do
    # Simulate code generation based on language and difficulty
    system =
      """
      You are a code generation assistant that creates diverse, real-world programming exercises.

      DIFFICULTY LEVELS:
      - Easy: Simple syntax, common patterns, basic control structures, short variable names
      - Medium: Moderate complexity, some nesting, standard library usage, descriptive names
      - Hard: Complex syntax, advanced patterns, multiple concepts combined, longer identifiers

      REQUIREMENTS:
      1. Generate exactly #{lines} lines of functional, compilable code
      2. Use real-world scenarios (web apps, data processing, algorithms, etc.)
      3. Follow language best practices and conventions
      4. Vary code patterns - avoid repetitive structures
      5. Include diverse concepts: functions, classes, loops, conditionals, data structures
      6. Use realistic variable/function names, not placeholders

      OUTPUT FORMAT:
      Return only the raw code without markdown, comments explaining the exercise, or extra text.
      The code should be immediately usable and represent a complete, meaningful snippet.
      """

    prompt = """
    Generate at least #{lines} lines of #{language} code with #{difficulty} typing difficulty.

    Context: Create a practical code snippet that demonstrates real-world usage.
    Ensure variety in syntax patterns and avoid repetitive structures.
    """

    case send_to_gemini(system, prompt) do
      %Req.Response{status: 200, body: body} ->
        result =
          parse_body(body)
          |> parse_json()

        {:ok, result}

      %Req.Response{status: status, body: body} ->
        {:error, status, parse_error(body)}
    end
  end

  def analyze(session) do
    system =
      """
      You are a specialized AI assistant that evaluates developer typing proficiency for programming languages.
      """

    prompt =
      """
      Analyze typing test results and determine programming language suitability based on typing performance.
      Input Data:

      Typing test results:
      Difficulty: #{session.difficulty}
      Code Length: #{String.length(session.code_challenge)} chars
      #{round(String.length(session.code_challenge) / session.time_completion * 60)} Characters/Min
      #{round(session.streak / (session.streak + session.wrong) * 100)}% Accuracy
      #{session.time_completion}s Time Taken
      #{session.wrong} Wrong

      Target programming language: #{session.language}


      Context: Typing proficiency directly impacts developer productivity, coding speed, and idea implementation. Different programming languages have varying typing demands - some require extensive special character usage, others have verbose syntax, while some leverage code completion tools more heavily.

      Analysis Framework:

      Evaluate Core Metrics: Examine characters per minute (CPM), accuracy, and other provided metrics
      Language-Specific Assessment: Consider the chosen language's typing characteristics:

      Special character frequency (brackets, operators, symbols)
      Syntax verbosity vs. conciseness
      Common development patterns and code completion reliance

      Impact Assessment: Determine how typing skills affect efficiency in the specific language

      Output Requirements:
      Analysis:

      [Bullet point analysis of typing strengths and weaknesses]
      [Language-specific typing requirements evaluation]
      [Performance impact assessment for chosen programming language]

      Call to Action:
      [Provide encouraging feedback with specific improvement recommendations]
      Verdict:
      [Select one: "Highly Suitable" | "Suitable" | "Marginally Suitable" | "Not Suitable"]
      [Include brief justification]
      Important: Base your assessment exclusively on the typing test data and programming language characteristics. Do not infer other programming skills or experience levels.
      """

    case send_to_gemini(system, prompt) do
      %Req.Response{status: 200, body: body} ->
        result =
          parse_body(body)
          |> parse_json()

        result

      %Req.Response{status: status, body: body} ->
        {:error, status, parse_error(body)}
    end
  end

  def send_to_gemini(system, prompt, _lines \\ 10) do
    url =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent?key=#{System.get_env("GEMINI_API_KEY")}"

    http_client = Application.get_env(:coderacer, :http_client, Req)

    http_client.post!(url,
      json: %{
        contents: [
          %{role: "model", parts: [%{text: system}]},
          %{role: "user", parts: [%{text: prompt}]}
        ],
        generationConfig: %{
          temperature: 0.7,
          topP: 0.8,
          max_output_tokens: 65_536,
          responseMimeType: "application/json",
          responseSchema: %{
            type: "object",
            properties: %{
              response: %{
                type: "string",
                description: "Raw source code without markdown formatting"
              }
            },
            required: ["response"]
          }
        }
      }
    )
  end

  def parse_body(body) do
    body
    |> Map.get("candidates")
    |> List.first()
    |> Map.get("content")
    |> Map.get("parts")
    |> List.first()
    |> Map.get("text")
  end

  def parse_error(body) when is_map(body) do
    case Map.get(body, "error") do
      nil -> nil
      error_map -> Map.get(error_map, "message")
    end
  end

  def parse_error(nil), do: nil

  def parse_json(json) do
    case Jason.decode(json) do
      {:ok, decoded} ->
        Map.get(decoded, "response")

      {:error, error} ->
        {:error, error}
    end
  end
end
