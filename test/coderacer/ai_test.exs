defmodule Coderacer.AITest do
  use ExUnit.Case

  test "generate/2 returns valid code for supported language and difficulty" do
    code = Coderacer.AI.generate("JavaScript", 2, "easy")

    assert is_binary(code), "Expected generated code to be a binary string"
    assert String.length(code) > 0, "Expected generated code to be non-empty"
  end

  test "to make sure generate/2 retunrs only code and not some markdown triple tick"
end
