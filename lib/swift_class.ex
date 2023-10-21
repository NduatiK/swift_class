defmodule SwiftClass do
  # @moduledoc false
  import NimbleParsec
  alias SwiftClass.Modifiers
  # alias SwiftClass.Tokens
  import SwiftClass.Blocks

  def parse(input, opts \\ []) do
    result =
      input
      |> SwiftClass.Modifiers.modifiers(opts)
      |> SwiftClass.Parser.error_from_result()

    case result do
      {:ok, [output], a, b, c, d} ->
        {:ok, output, a, b, c, d}

      other ->
        other
    end
  end

  defparsec(
    :parse_class_block,
    repeat(SwiftClass.Parser.start(), parsec(:class_block))
  )
end
