defmodule SwiftClass.HelperFunctions do
  @moduledoc false
  import NimbleParsec
  import SwiftClass.Tokens
  import SwiftClass.Expressions

  import SwiftClass.Parser
  # import SwiftClass.Tokens
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
    # start()
    # |> mark_line(:elixir_code, fn ->
    #   mark_line(:function, fn ->
    |> concat(
      function_names
      |> Enum.map(&string(&1))
      |> choice()
      |> enclosed("(", variable(), ")", [])
      |> post_traverse({PostProcessors, :to_function_call_ast, []})
      |> post_traverse({PostProcessors, :tag_as_elixir_code, []})
    )

    #   end)
    # end)
    |> label("a 1-arity helper function (#{Enum.join(function_names, ", ")})")
  end
end
