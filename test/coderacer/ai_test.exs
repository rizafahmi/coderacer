defmodule Coderacer.AITest do
  use ExUnit.Case

  @moduletag skip_ai_mock: true

  # Mock module to intercept HTTP requests
  defmodule MockReq do
    def post!(url, opts) do
      # Verify the request is going to the correct endpoint
      assert String.contains?(url, "generativelanguage.googleapis.com")

      # Check if this is an analyze request by looking at the prompt
      contents = get_in(opts, [:json, :contents]) || []
      user_content = Enum.at(contents, 1) || %{}
      parts = Map.get(user_content, :parts, [])
      first_part = Enum.at(parts, 0) || %{}
      prompt = Map.get(first_part, :text, "")

      response_text =
        if String.contains?(prompt, "Analyze") do
          Jason.encode!(%{
            "response" => """
            Analysis:
            • Good typing speed and accuracy for a medium difficulty challenge
            • JavaScript requires moderate special character usage
            • Performance indicates solid foundation for this language

            Call to Action:
            Keep practicing to improve speed while maintaining accuracy!

            Verdict:
            Suitable - Your typing skills are well-matched for JavaScript development
            """
          })
        else
          Jason.encode!(%{
            "response" => "console.log('Hello, World!');\nconst x = 42;"
          })
        end

      # Return a mock response
      %Req.Response{
        status: 200,
        body: %{
          "candidates" => [
            %{
              "content" => %{
                "parts" => [
                  %{
                    "text" => response_text
                  }
                ]
              }
            }
          ]
        }
      }
    end
  end

  # Mock module for error cases
  defmodule MockReqError do
    def post!(_url, _opts) do
      %Req.Response{
        status: 429,
        body: %{
          "error" => %{
            "message" => "Rate limit exceeded"
          }
        }
      }
    end
  end

  # Mock module for malformed JSON response
  defmodule MockReqMalformedJson do
    def post!(_url, _opts) do
      %Req.Response{
        status: 200,
        body: %{
          "candidates" => [
            %{
              "content" => %{
                "parts" => [
                  %{
                    "text" => "invalid json content"
                  }
                ]
              }
            }
          ]
        }
      }
    end
  end

  # Mock module for empty candidates
  defmodule MockReqEmptyCandidates do
    def post!(_url, _opts) do
      %Req.Response{
        status: 200,
        body: %{
          "candidates" => []
        }
      }
    end
  end

  setup do
    # Replace the real Req module with our mock
    Application.put_env(:coderacer, :http_client, MockReq)
    on_exit(fn -> Application.delete_env(:coderacer, :http_client) end)
    :ok
  end

  test "generate/2 returns valid code for supported language and difficulty" do
    {:ok, code} = Coderacer.AI.generate("JavaScript", "easy", 2)

    assert is_binary(code), "Expected generated code to be a binary string"
    assert String.length(code) > 0, "Expected generated code to be non-empty"
    assert code == "console.log('Hello, World!');\nconst x = 42;"
  end

  test "generate/3 with default lines parameter" do
    {:ok, code} = Coderacer.AI.generate("Python", "medium")
    assert is_binary(code)
    assert String.length(code) > 0
  end

  test "to make sure generate/2 returns only code and not some markdown triple tick" do
    {:ok, code} = Coderacer.AI.generate("JavaScript", "easy", 2)
    assert String.contains?(code, "```") == false
  end

  test "generate/2 handles HTTP error responses" do
    # Configure the error mock
    Application.put_env(:coderacer, :http_client, MockReqError)

    # Test error handling
    assert {:error, 429, "Rate limit exceeded"} = Coderacer.AI.generate("JavaScript", "easy", 2)
  end

  test "generate/2 handles malformed JSON gracefully" do
    Application.put_env(:coderacer, :http_client, MockReqMalformedJson)

    result = Coderacer.AI.generate("JavaScript", "easy", 2)

    assert {:ok,
            {:error, %Jason.DecodeError{position: 0, token: nil, data: "invalid json content"}}} =
             result
  end

  test "generate/2 handles empty candidates array" do
    Application.put_env(:coderacer, :http_client, MockReqEmptyCandidates)

    assert_raise BadMapError, fn ->
      Coderacer.AI.generate("JavaScript", "easy", 2)
    end
  end

  test "parse_json/1 handles valid JSON" do
    valid_json = Jason.encode!(%{"response" => "test code"})
    assert Coderacer.AI.parse_json(valid_json) == "test code"
  end

  test "parse_json/1 handles invalid JSON" do
    invalid_json = "invalid json"
    assert {:error, _} = Coderacer.AI.parse_json(invalid_json)
  end

  test "parse_error/1 extracts error message from body" do
    error_body = %{"error" => %{"message" => "Test error"}}
    assert Coderacer.AI.parse_error(error_body) == "Test error"
  end

  test "parse_error/1 handles missing error message" do
    error_body = %{"error" => %{}}
    assert Coderacer.AI.parse_error(error_body) == nil
  end

  test "parse_error/1 handles malformed error body" do
    error_body = %{"not_error" => "something"}
    assert Coderacer.AI.parse_error(error_body) == nil
  end

  test "generate/2 with different languages" do
    languages = ["JavaScript", "Python", "Elixir", "Go", "Rust", "C++", "Java"]

    for language <- languages do
      {:ok, code} = Coderacer.AI.generate(language, "easy", 2)
      assert is_binary(code)
      assert String.length(code) > 0
    end
  end

  test "generate/2 with different difficulties" do
    difficulties = ["easy", "medium", "hard"]

    for difficulty <- difficulties do
      {:ok, code} = Coderacer.AI.generate("JavaScript", difficulty, 2)
      assert is_binary(code)
      assert String.length(code) > 0
    end
  end

  test "generate/2 with different line counts" do
    line_counts = [1, 2, 5, 10]

    for lines <- line_counts do
      {:ok, code} = Coderacer.AI.generate("JavaScript", "easy", lines)
      assert is_binary(code)
      assert String.length(code) > 0
    end
  end

  test "analyze/1 returns analysis for session" do
    # Create a mock session
    session = %{
      difficulty: "medium",
      code_challenge: "console.log('test');",
      time_completion: 30,
      streak: 15,
      wrong: 2,
      language: "javascript"
    }

    result = Coderacer.AI.analyze(session)

    assert is_binary(result)
    assert String.contains?(result, "Analysis:")
    assert String.contains?(result, "Call to Action:")
    assert String.contains?(result, "Verdict:")
  end
end
