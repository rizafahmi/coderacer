defmodule Coderacer.AITest do
  use ExUnit.Case

  # Mock module to intercept HTTP requests
  defmodule MockReq do
    def post!(url, _opts) do
      # Verify the request is going to the correct endpoint
      assert String.contains?(url, "generativelanguage.googleapis.com")

      # Return a mock response with a known code snippet
      %Req.Response{
        status: 200,
        body: %{
          "candidates" => [
            %{
              "content" => %{
                "parts" => [
                  %{
                    "text" =>
                      Jason.encode!(%{
                        "response" => "console.log('Hello, World!');\nconst x = 42;"
                      })
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

  setup do
    # Replace the real Req module with our mock
    Application.put_env(:coderacer, :http_client, MockReq)
    on_exit(fn -> Application.delete_env(:coderacer, :http_client) end)
    :ok
  end

  test "generate/2 returns valid code for supported language and difficulty" do
    code = Coderacer.AI.generate("JavaScript", "easy", 2)

    assert is_binary(code), "Expected generated code to be a binary string"
    assert String.length(code) > 0, "Expected generated code to be non-empty"
    assert code == "console.log('Hello, World!');\nconst x = 42;"
  end

  test "to make sure generate/2 returns only code and not some markdown triple tick" do
    code = Coderacer.AI.generate("JavaScript", "easy", 2)
    assert String.contains?(code, "```") == false
  end

  test "generate/2 handles HTTP error responses" do
    # Configure the error mock
    Application.put_env(:coderacer, :http_client, MockReqError)

    # Test error handling
    assert {:error, 429, "Rate limit exceeded"} = Coderacer.AI.generate("JavaScript", 2, "easy")
  end
end
