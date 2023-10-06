defmodule SwiftClass.Tokens do
  import NimbleParsec

  #
  # Literals
  #

  def true_value() do
    string("true")
    |> replace(true)
  end

  def false_value() do
    string("false")
    |> replace(false)
  end

  def boolean() do
    choice([true_value(), false_value()])
  end

  def null(), do: replace(string("nil"), nil)

  def minus(), do: string("-")

  def plus(), do: string("+")

  def int() do
    optional(minus())
    |> concat(integer(min: 1))
    |> reduce({Enum, :join, [""]})
    |> map({String, :to_integer, []})
  end

  def frac() do
    concat(string("."), integer(min: 1))
  end

  def float() do
    int()
    |> concat(frac())
    |> reduce({Enum, :join, [""]})
    |> map({String, :to_float, []})
  end

  def atom() do
    ignore(string(":"))
    |> concat(word())
    |> map({String, :to_atom, []})
  end

  def string() do
    ignore(string(~s(")))
    |> repeat(
      lookahead_not(ascii_char([?"]))
      |> choice([string(~s(\")), utf8_char([])])
    )
    |> ignore(string(~s(")))
    |> reduce({List, :to_string, []})
  end

  def literal() do
    choice([
      float(),
      int(),
      boolean(),
      null(),
      atom(),
      string()
    ])
  end

  #
  # Whitespace
  #

  def whitespace(opts) do
    utf8_string([?\s, ?\n, ?\r, ?\t], opts)
  end

  def whitespace_except(exception, opts) do
    utf8_string(Enum.reject([?\s, ?\n, ?\r, ?\t], &(<<&1>> == exception)), opts)
  end

  def ignore_whitespace(combinator \\ empty()) do
    combinator |> ignore(optional(whitespace(min: 1)))
  end

  # @tuple_children [
  #   parsec(:nested_attribute),
  #   atom(),
  #   boolean,
  #   variable(),
  #   string()
  # ]

  # def tuple() do
  #   ignore_whitespace()
  #   |> ignore(string("{"))
  #   |> comma_separated_list(choice(@tuple_children))
  #   |> ignore(string("}"))
  #   |> ignore_whitespace()
  #   |> wrap()
  # end

  #
  # AST
  #

  defp variable_word() do
    ascii_string([?a..?z, ?A..?Z, ?_], 1)
    |> ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_], min: 1)
    |> reduce({Enum, :join, [""]})
  end

  # This is a variable that is found inside an Elixir
  # context and is
  def quoted_variable() do
    # Variables cant start with numbers
    variable_word()
    |> post_traverse({:to_elixir_variable_ast, []})
  end

  # This is a variable that is found inside the normal context
  # and must therefore be marked as elixir code
  def variable() do
    # Variables cant start with numbers
    quoted_variable()
    |> post_traverse({:tag_as_elixir_code, []})
  end

  def word() do
    ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_], min: 1)
  end

  def module_name() do
    ascii_string([?A..?Z], 1)
    |> ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_], min: 0)
    |> reduce({Enum, :join, [""]})
  end

  def enclosed(start \\ empty(), open, combinator, close) do
    start
    |> ignore_whitespace()
    |> ignore(string(open))
    |> ignore_whitespace()
    |> concat(combinator)
    |> ignore_whitespace()
    |> ignore(string(close))
    |> ignore_whitespace()
  end

  #
  # Collections
  #

  def comma_separated_list(combinator \\ empty(), elem_combinator) do
    delimiter_separated_list(combinator, elem_combinator, ",", true)
  end

  def non_empty_comma_separated_list(combinator, elem_combinator) do
    delimiter_separated_list(combinator, elem_combinator, ",", false)
  end

  def delimiter_separated_list(combinator, elem_combinator, delimiter, allow_empty \\ true) do
    #  1+ elems
    non_empty =
      elem_combinator
      |> ignore_whitespace()
      |> repeat(
        ignore(string(delimiter))
        |> ignore_whitespace()
        |> concat(elem_combinator)
        |> ignore_whitespace()
      )

    empty_ = ignore_whitespace(empty())

    if allow_empty do
      combinator
      |> choice([non_empty, empty_])
    else
      combinator
      |> concat(non_empty)
    end
  end

  def newline_separated_list(elem_combinator) do
    #  1+ elems
    ignore_whitespace()
    |> concat(elem_combinator)
    |> repeat(
      choice([
        ignore(optional(whitespace_except("\n", min: 1)))
        |> ignore(string("\n"))
        |> ignore(whitespace(min: 1))
        |> concat(elem_combinator),
        # Require at least one whitespace
        ignore(whitespace(min: 1))
      ])
    )
  end
end
