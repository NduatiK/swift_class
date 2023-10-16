defmodule SwiftClass.HelperFunctions do
  @moduledoc false
  import NimbleParsec
  import SwiftClass.Tokens, only: [start: 0, variable: 0, enclosed: 4, mark_line: 2, mark_line: 3]
  alias SwiftClass.PostProcessors

  @helper_functions [
    "to_atom",
    "to_integer",
    "to_float",
    "to_boolean",
    "camelize",
    "underscore"
  ]

  def helper_function(opts \\ []) do
    additional_functions = Keyword.get(opts, :additional, [])
    function_names = @helper_functions ++ additional_functions

    start()
    |> mark_line(:elixir_code, fn ->
      mark_line(:function, fn ->
        function_names
        |> Enum.map(&string(&1))
        |> choice()
        |> enclosed("(", variable(), ")")
        |> post_traverse({PostProcessors, :to_function_call_ast, []})
        |> post_traverse({PostProcessors, :tag_as_elixir_code, []})
      end)
    end)
    |> label("a 1-arity helper function (#{Enum.join(function_names, ", ")})")
  end
end
