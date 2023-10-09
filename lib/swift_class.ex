defmodule SwiftClass do
  @moduledoc false
  import NimbleParsec
  import SwiftClass.Modifiers
  import SwiftClass.Blocks
  import SwiftClass.PostProcessors
  import SwiftClass.Tokens

  def parse(input) do
    case SwiftClass.Modifiers.modifiers(input) do
      {:ok, [output], a, b, c, d} ->
        {:ok, output, a, b, c, d}

      other ->
        other
    end
  end

  defparsec(:parse_class_block, repeat(parsec(:class_block)))
end
