defmodule CoderacerWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use CoderacerWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint CoderacerWeb.Endpoint

      use CoderacerWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import CoderacerWeb.ConnCase
    end
  end

  setup tags do
    Coderacer.DataCase.setup_sandbox(tags)

    # Mock the HTTP client for AI functions to avoid real API calls during tests
    unless tags[:skip_ai_mock] do
      setup_ai_mock()
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  defp setup_ai_mock do
    Application.put_env(:coderacer, :http_client, CoderacerWeb.TestHttpClient)

    ExUnit.Callbacks.on_exit(fn ->
      Application.delete_env(:coderacer, :http_client)
    end)
  end
end

defmodule CoderacerWeb.TestHttpClient do
  @moduledoc """
  Mock HTTP client for testing AI API calls.

  This module provides mock responses for Gemini API calls to avoid
  making real HTTP requests during tests.
  """

  def post!(url, _opts) do
    if String.contains?(url, "generativelanguage.googleapis.com") do
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
                  }
                ]
              }
            }
          ]
        }
      }
    else
      # Default fallback
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
                        "response" => "// Mock response"
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
end
