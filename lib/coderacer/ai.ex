defmodule Coderacer.AI do
  @moduledoc """
  Module documentation for Coderacer.AI.
  """
  def generate(language, difficulty, lines \\ 10) do
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

    case ask_vertex(system, prompt) do
      %Req.Response{status: 200, body: body} ->
        result =
          parse_body(body)
          |> parse_json()

        {:ok, result}

      %Req.Response{status: status, body: body} ->
        {:error, status, parse_error(body)}
    end
  end

  def ask_vertex(system, prompt) do
    project_id = "genai-441313"
    location_id = "global"
    api_endpoint = "aiplatform.googleapis.com"
    model_id = "gemini-2.0-flash-lite-001"
    generate_content_api = "generateContent"

    url =
      "https://#{api_endpoint}/v1/projects/#{project_id}/locations/#{location_id}/publishers/google/models/#{model_id}:#{generate_content_api}"

    http_client = Application.get_env(:coderacer, :http_client, Req)

    http_client.post!(
      url,
      headers: [
        {"Content-Type", "application/json"},
        {"Authorization", "Bearer #{System.get_env("VERTEX_API_KEY")}"}
      ],
      json: %{
        contents: [
          %{role: "user", parts: [%{text: prompt}]}
        ],
        systemInstruction: %{
          parts: [%{text: system}]
        },
        generationConfig: %{
          temperature: 0.7,
          topP: 0.8,
          max_output_tokens: 6_400,
          responseMimeType: "application/json",
          responseSchema: %{
            type: "object",
            properties: %{
              response: %{
                type: "STRING",
                description:
                  "Analysis of the typing test results and programming language suitability"
              }
            },
            required: ["response"]
          }
        },
        safetySettings: [
          %{
            category: "HARM_CATEGORY_HATE_SPEECH",
            threshold: "OFF"
          },
          %{
            category: "HARM_CATEGORY_DANGEROUS_CONTENT",
            threshold: "OFF"
          },
          %{
            category: "HARM_CATEGORY_SEXUALLY_EXPLICIT",
            threshold: "OFF"
          },
          %{
            category: "HARM_CATEGORY_HARASSMENT",
            threshold: "OFF"
          }
        ]
      }
    )
  end

  def send(prompt, lines \\ 10) do
    url =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=#{System.get_env("GEMINI_API_KEY")}"

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

    http_client = Application.get_env(:coderacer, :http_client, Req)

    http_client.post!(url,
      json: %{
        contents: [
          %{role: "assistant", parts: [%{text: system}]},
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
