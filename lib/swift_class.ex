defmodule SwiftClass do
  # @moduledoc false
  import NimbleParsec
  alias SwiftClass.Modifiers
  # alias SwiftClass.Tokens
  import SwiftClass.Blocks

  def parse(input, opts \\ []) do
    file = Keyword.get(opts, :file, "")

    result =
      input
      |> SwiftClass.Modifiers.modifiers(opts)
      |> SwiftClass.Parser.error_from_result()

    case result do
      {:ok, [output], a, b, c, d} -> output

      {:ok, output, a, b, c, d} -> output

      {:error, message, _unconsumed, _context, {line, _}, _} ->
        
        raise SyntaxError,
          description: message,
          file: file,
          line: line
    end
  end

  def parse_class_block(input, opts \\ []) do
    file = Keyword.get(opts, :file, "")

    result =
      input
      |> parse_class_block_(opts)
      |> SwiftClass.Parser.error_from_result()

    case result do
      {:ok, output, a, b, c, d} -> output

      {:error, message, _unconsumed, _context, {line, _}, _} ->
        raise SyntaxError,
          description: message,
          file: file,
          line: line
    end
  end

  defparsec(
    :parse_class_block_,
    repeat(SwiftClass.Parser.start(), parsec(:class_block))
  )
end
