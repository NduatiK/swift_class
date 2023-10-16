defmodule SwiftClass.Tokens do
  import NimbleParsec
  alias SwiftClass.PostProcessors
  import SwiftClass.Parser

  def start() do
    pre_traverse(empty(), {PostProcessors, :prepare_context, []})
  end

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
    |> lookahead_not(ascii_char([?a..?z, ?A..?Z, ?_]))
    |> reduce({Enum, :join, [""]})
    |> map({String, :to_integer, []})
  end

  def frac() do
    concat(string("."), integer(min: 1))
  end

  def float() do
    int()
    |> concat(frac())
    |> lookahead_not(ascii_char([?a..?z, ?A..?Z, ?_]))
    |> reduce({Enum, :join, [""]})
    |> map({String, :to_float, []})
  end

  def atom() do
    ignore(string(":"))
    |> concat(word())
    |> map({String, :to_atom, []})
  end

  def double_quoted_string() do
    ignore(string(~s(")))
    |> repeat(
      lookahead_not(ascii_char([?"]))
      |> choice([string(~s(\")), utf8_char([])])
    )
    |> ignore(string(~s(")))
    |> reduce({List, :to_string, []})
  end

  def literal() do
    one_of([
      {float(), "float"},
      {int(), "int"},
      {boolean(), "boolean"},
      {null(), "nil"},
      {atom(), "atom"},
      {double_quoted_string(), "string"}
    ])
  end

  #
  # Whitespace
  #
  @whitespace_chars [?\s, ?\n, ?\r, ?\t]
  def whitespace(opts) do
    utf8_string(@whitespace_chars, opts)
  end

  def whitespace_except(exception, opts) do
    utf8_string(Enum.reject(@whitespace_chars, &(<<&1>> == exception)), opts)
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

  def variable() do
    ascii_string([?a..?z, ?A..?Z, ?_], 1)
    |> ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_], min: 0)
    |> reduce({Enum, :join, [""]})
    |> post_traverse({PostProcessors, :to_elixir_variable_ast, []})
  end

  # def ascii_chars() do
  #   ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_], min: 1)
  # end

  def word() do
    ascii_string([?a..?z, ?A..?Z, ?_], 1)
    |> ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_], min: 0)
    |> reduce({Enum, :join, [""]})
  end

  def modifier_name() do
    choice([
      ascii_string([?a..?z, ?A..?Z, ?_], 1)
      |> ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_], min: 0)
      |> reduce({Enum, :join, [""]})
      |> label("ASCII letter or underscore followed zero or more"),
      error(expected: "a modifier name", show_got?: true)
    ])
  end

  def module_name() do
    ascii_string([?A..?Z], 1)
    |> ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_], min: 0)
    |> reduce({Enum, :join, [""]})
  end

  def enclosed(start \\ empty(), open, combinator, close, opts \\ []) do
    allow_empty = Keyword.get(opts, :allow_empty, true)
    optional = Keyword.get(opts, :optional, false)

    maybe_errors =
      SwiftClass.Parser.get_one_of_errors(combinator)

    enclosed_without_elems =
      ignore(string(open))
      |> ignore_whitespace()
      |> ignore(string(close))

    enclosed_with_elems =
      ignore(string(open))
      |> ignore_whitespace()
      |> concat(combinator)
      |> ignore_whitespace()
      |> ignore(string(close))
      |> ignore_whitespace()

    error =
      if maybe_errors do
        error(expected: "\"#{open}<CHILD>#{close}\"\n\twhere <CHILD> is #{maybe_errors}")
      else
        error(expected: "to match #{open}#{close} or #{open} elements #{close}")
      end

    start
    |> ignore_whitespace()
    |> choice(
      if allow_empty do
        [
          enclosed_without_elems,
          enclosed_with_elems
        ] ++ if(not optional, do: [error], else: [empty()])
      else
        [enclosed_with_elems] ++ if(not optional, do: [error], else: [empty()])
      end
    )
  end

  #
  # Collections
  #

  def comma_separated_list(start \\ empty(), elem_combinator, opts \\ []) do
    delimiter_separated_list(start, elem_combinator, ",", true, opts)
  end

  def non_empty_comma_separated_list(start, elem_combinator, opts \\ []) do
    delimiter_separated_list(start, elem_combinator, ",", false, opts)
  end

  defp delimiter_separated_list(start, elem_combinator, delimiter, allow_empty, opts) do
    fail = Keyword.get(opts, :fail, true)

    maybe_errors =
      SwiftClass.Parser.get_one_of_errors(elem_combinator)

    #  1+ elems
    non_empty =
      elem_combinator
      |> repeat(
        ignore_whitespace()
        |> ignore(string(delimiter))
        |> ignore_whitespace()
        |> concat(elem_combinator)
      )

    empty_ = ignore_whitespace(empty())

    error =
      if maybe_errors do
        error(
          expected:
            "a \"#{delimiter}\" separated sequence containing one of the following: \n#{indent(maybe_errors)}"
        )
      else
        error(expected: "a \"#{delimiter}\" separated sequence")
      end

    if fail do
      if allow_empty do
        start
        |> choice([non_empty, empty_, error])
      else
        start
        |> concat(choice([non_empty, error]))
      end
    else
      if allow_empty do
        start
        |> choice([non_empty, empty_])
      else
        start
        |> concat(non_empty)
      end
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

  def key_value_pair() do
    ignore_whitespace()
    |> concat(word())
    |> concat(ignore(string(":")))
    |> ignore(whitespace(min: 1))
    |> one_of(
      [
        {literal(), ~s'a number, string, nil, boolean or :atom'},
        {parsec(:ime), ~s'an IME eg ‘Color.red’ or ‘.largeTitle’ or ‘Color.to_ime(variable)’'},
        {parsec(:nested_attribute), ~s'a modifier eg ‘foo(bar())’'},
        {parsec(:key_value_list),
         ~s'a list of keyword pairs eg ‘[style: :dashed]’, ‘[size: 12]’ or ‘[lineWidth: lineWidth]’'},
        {variable(), ~s|a variable defined in the class header eg ‘color_name’|}
      ],
      prefix: "the value in this keyword list to be ",
      error_range_parser:
        choice([
          string("["),
          SwiftClass.Parser.non_whitespace()
        ])
    )
    |> post_traverse({PostProcessors, :to_keyword_tuple_ast, []})
  end

  def key_value_pairs() do
    ignore_whitespace()
    # -- TODO: Figure out how to drop errors
    |> non_empty_comma_separated_list(key_value_pair(), fail: false)
    |> wrap()
  end

  #
  # Error
  #

  def mark_line(start \\ empty(), name, gen_combinator) do
    start
    |> concat(gen_combinator.())
    |> pre_traverse({PostProcessors, :mark_line, [name]})
    |> post_traverse({PostProcessors, :unmark_line, [name]})
  end
end
