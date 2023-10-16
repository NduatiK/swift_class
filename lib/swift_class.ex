defmodule SwiftClass do
  @moduledoc false
  import NimbleParsec
  alias SwiftClass.Modifiers
  alias SwiftClass.Tokens
  import SwiftClass.Blocks

  def parse(input) do
    case Modifiers.modifiers(input) do
      {:ok, [output], a, b, c, d} ->
        {:ok, output, a, b, c, d}

      other ->
        other
    end
  end

  defparsec(
    :parse_class_block,
    Tokens.start()
    |> repeat(parsec(:class_block))
  )
end
