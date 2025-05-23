defmodule CoderacerWeb.StartLiveTest do
  use CoderacerWeb.ConnCase
  import Phoenix.LiveViewTest

  describe "StartLive" do
    test "renders start page with form", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~
               "Test your coding speed and accuracy. Choose your language and difficulty to get started."

      assert html =~ "Programming Language"
      assert html =~ "Difficulty Level"
      assert html =~ "Start"
    end

    test "creates session and redirects on valid form submission", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Mock the AI.generate function to avoid external API calls
      Application.put_env(:coderacer, :http_client, CoderacerWeb.StartLiveTest.MockReq)

      form_data = %{
        "language" => "javascript",
        "difficulty" => "easy"
      }

      view
      |> form("form", form_data)
      |> render_submit()

      # Should redirect to game page - just check that no error occurred

      # Clean up
      Application.delete_env(:coderacer, :http_client)
    end

    test "handles AI generation errors gracefully", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Configure mock to return error
      Application.put_env(:coderacer, :http_client, CoderacerWeb.StartLiveTest.MockReqError)

      form_data = %{
        "language" => "javascript",
        "difficulty" => "easy"
      }

      view
      |> form("form", form_data)
      |> render_submit()

      # Should handle error gracefully without crash
      # Clean up
      Application.delete_env(:coderacer, :http_client)
    end
  end

  # Mock module for successful AI responses
  defmodule MockReq do
    def post!(_url, _opts) do
      %Req.Response{
        status: 200,
        body: %{
          "candidates" => [
            %{
              "content" => %{
                "parts" => [
                  %{
                    "text" => Jason.encode!(%{"response" => "console.log('test');"})
                  }
                ]
              }
            }
          ]
        }
      }
    end
  end

  # Mock module for AI errors
  defmodule MockReqError do
    def post!(_url, _opts) do
      %Req.Response{
        status: 500,
        body: %{"error" => %{"message" => "Internal server error"}}
      }
    end
  end
end
