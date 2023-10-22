defmodule SwiftClass.Blocks do
  @moduledoc false
  import NimbleParsec
  import SwiftClass.Tokens
  import SwiftClass.Expressions
  import SwiftClass.Modifiers
  import SwiftClass.PostProcessors

  string_with_variable =
    double_quoted_string()
    |> ignore_whitespace()
    |> ignore(string("<>"))
    |> ignore_whitespace()
    |> concat(variable())
    |> post_traverse({:block_open_with_variable_to_ast, []})

  block_open =
    choice([
      string_with_variable,
      double_quoted_string()
    ])
    |> optional(
      ignore_whitespace()
      |> ignore(string(","))
      |> ignore_whitespace()
      |> concat(key_value_pairs())
    )
    |> ignore_whitespace()
    |> ignore(string("do"))
    |> post_traverse({:block_open_to_ast, []})

  block_close =
    ignore_whitespace()
    |> ignore(string("end"))

  block_contents =
    repeat(
      lookahead_not(block_close)
      |> ignore_whitespace()
      |> parsec(:modifier)
    )
    |> ignore_whitespace()
    |> wrap()

  defcombinator(
    :class_block,
    ignore_whitespace()
    |> concat(block_open)
    |> concat(block_contents)
    |> concat(block_close)
    |> post_traverse({:wrap_in_tuple, []}),
    export_combinator: true
  )
end
