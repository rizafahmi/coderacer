defmodule Coderacer.AI do
  def generate(language, lines, difficulty) do
    # Simulate code generation based on language and difficulty
    prompt = "Generate #{lines} lines of code in #{language} that is #{difficulty} to type."

    case send(prompt) do
      %Req.Response{status: 200, body: body} ->
        parse_body(body)
        |> parse_json()

      %Req.Response{status: status, body: body} ->
        {:error, status, parse_error(body)}
    end
  end

  def send(prompt) do
    url =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=#{System.get_env("GEMINI_API_KEY")}"

    result =
      Req.post!(url,
        json: %{
          contents: [%{role: "user", parts: [%{text: prompt}]}],
          generationConfig: %{
            temperature: 0.5,
            topP: 0.8,
            max_output_tokens: 65536,
            responseMimeType: "application/json",
            responseSchema: %{
              type: "object",
              properties: %{
                response: %{
                  type: "string"
                }
              }
            }
          }
        }
      )

    result
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

  def parse_error(body) do
    body
    |> Map.get("error")
    |> Map.get("message")
  end

  def parse_json(json) do
    case Jason.decode(json) do
      {:ok, decoded} ->
        Map.get(decoded, "response")

      {:error, error} ->
        {:error, error}
    end
  end
end
