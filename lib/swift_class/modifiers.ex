defmodule SwiftClass.Modifiers do
  import NimbleParsec
  import SwiftClass.Expressions
  import SwiftClass.Tokens
  import SwiftClass.Parser
  alias SwiftClass.PostProcessors

  defcombinator(
    :key_value_list,
    enclosed("[", key_value_pairs(generate_error?: false, allow_empty?: false), "]",
      allow_empty?: false
    )
  )

  implicit_ime = fn is_initial ->
    ignore(string("."))
    |> concat(word())
    |> wrap(
      choice([
        ignore(string("()")),
        lookahead(utf8_char(String.to_charlist(".)")))
        |> concat(empty()),
        parsec(:modifier_brackets)
      ])
    )
    |> post_traverse({PostProcessors, :to_implicit_ime_ast, [is_initial]})
  end

  # Foo.bar
  # Foo.baz(0.1)
  scoped_ime =
    module_name()
    |> ignore(string("."))
    |> concat(word())
    |> wrap(
      choice([
        ignore(string("()")),
        lookahead(utf8_char(String.to_charlist(".)")))
        |> concat(empty()),
        parsec(:modifier_brackets)
      ])
    )
    |> post_traverse({PostProcessors, :to_scoped_ime_ast, []})

  ime_function = fn is_initial ->
    if is_initial do
      empty()
    else
      ignore(string("."))
    end
    |> ignore(string("to_ime"))
    |> enclosed(
      "(",
      variable(
        force_error?: true,
        error_message: "Expected a variable",
        error_parser: non_whitespace(also_ignore: String.to_charlist(")"))
      )
      |> post_traverse({PostProcessors, :to_ime_function_call_ast, [is_initial]}),
      ")",
      []
    )
  end

  defcombinator(
    :ime,
    choice([
      # Scoped
      # Color.red
      scoped_ime,
      # to_ime(color)
      ime_function.(true),
      # Implicit
      # .red
      implicit_ime.(true)
    ])
    # scoped_ime
    |> repeat(
      choice([
        # <other_ime>.to_ime(color)
        ime_function.(false),
        # <other_ime>.red
        implicit_ime.(false)
      ])
    )
    |> post_traverse({PostProcessors, :chain_ast, []})
  )

  defcombinator(
    :attr,
    string("attr")
    |> enclosed(
      "(",
      expected(
        double_quoted_string(),
        error_message: "attr expects a string argument"
      ),
      ")",
      []
    )
    |> post_traverse({PostProcessors, :to_attr_ast, []})
  )

  defparsec(
    :nested_attribute,
    empty()
    |> one_of(
      [
        {parsec(:attr), "an attribute eg ‘attr(placeholder)’"},
        #
        {SwiftClass.HelperFunctions.helper_function(), "a helper function eg ‘to_float(number)"},
        #
        {
          frozen(parsec(:inner_modifier)),
          "a modifier eg ‘bold()’"
        },
        {variable(generate_error?: false),
         ~s|a variable defined in the class header eg ‘color_name’|}
      ],
      error_parser: non_whitespace(also_ignore: String.to_charlist(")]"))
    ),
    export_combinator: true
  )

  @modifier_arguments [
    {
      literal(error_parser: empty(), generate_error?: false),
      ~s'a number, string, nil, boolean or :atom'
    },
    {
      key_value_pairs(generate_error?: false, allow_empty?: false),
      ~s'a list of keyword pairs eg ‘style: :dashed’, ‘size: 12’ or  ‘style: [lineWidth: 1]’'
    },
    {parsec(:ime), ~s'an IME eg ‘Color.red’ or ‘.largeTitle’ or ‘Color.to_ime(variable)’'},
    {parsec(:nested_attribute), ~s'a modifier eg ‘foo(bar())’'},
    {
      variable(generate_error?: false),
      ~s|a variable defined in the class header eg ‘color_name’|
    }
  ]

  defcombinator(
    :modifier_arguments,
    # ignore_whitespace()
    # |> one_of(@modifier_arguments.(true))
    empty()
    |> comma_separated_list(
      one_of(empty(), @modifier_arguments,
        error_parser: non_whitespace(also_ignore: String.to_charlist(")"))
      ),
      allow_empty?: false,
      error_message:
        """
        Expected ‘(<modifier_arguments>)’ where <modifier_arguments> are a comma separated list of:
        #{label_from_named_choices(@modifier_arguments)}
        """
        |> String.trim()
    )
  )

  defcombinator(
    :modifier_brackets,
    # enclosed("(", comma_separated_list(one_of(@bracket_child)), ")")
    expected(
      choice([
        ignore(
          string("(")
          |> ignore_whitespace()
          |> string(")")
        ),
        enclosed(
          "(",
          parsec(:modifier_arguments),
          ")",
          allow_empty?: false
        )
      ]),
      error_message:
        """
        Expected ‘()’ or ‘(<modifier_arguments>)’ where <modifier_arguments> are a comma separated list of:
        #{label_from_named_choices(@modifier_arguments)}
        """
        |> String.trim()
    )
  )

  defcombinator(
    :inner_modifier_brackets,
    # enclosed("(", comma_separated_list(one_of(@bracket_child)), ")")
    choice([
      ignore(
        string("(")
        |> ignore_whitespace()
        |> string(")")
      ),
      enclosed(
        "(",
        parsec(:modifier_arguments),
        ")",
        allow_empty?: false
      )
    ])
  )

  defparsec(
    :inner_modifier,
    ignore_whitespace()
    |> concat(modifier_name())
    |> parsec(:inner_modifier_brackets)
    |> post_traverse({PostProcessors, :to_function_call_ast, []})
    # |> parsec(:modifier_brackets)
  )

  defparsec(
    :modifier,
    ignore_whitespace()
    |> concat(modifier_name())
    |> parsec(:modifier_brackets)
    |> post_traverse({PostProcessors, :to_function_call_ast, []}),    export_combinator: true

    # |> parsec(:modifier_brackets)
  )

  defparsec(
    :modifiers,
    SwiftClass.Parser.start()
    |> times(parsec(:modifier), min: 1),
    # parsec(:modifier),
    # |> repeat_while(
    #   choice([
    #     ignore_whitespace()
    #     |> eos(),
    #     parsec(:modifier)
    #   ]),
    #   {__MODULE__, :no_error, []}
    # ),

    export_combinator: true
  )

  # defparsec(
  #   :modifiers,
  #   SwiftClass.Parser.start()
  #   |> repeat_while(parsec(:modifier)
  #   |> ignore_whitespace(), {__MODULE__, :no_error, []}),
  #   # parsec(:modifier), min: 1),
  #   # |> expected(eos(),
  #   #   error_message: "expected nothing after the modifier"
  #   # ),
  #   export_combinator: true
  # )

  def no_error("", context, _, _) do
    IO.inspect("no_error _hlat")
    {:halt, context}
  end

  def no_error(_, context, _, _) do
    IO.inspect({"no_error", context})

    if SwiftClass.Parser.Context.has_error?(context) do
      {:halt, context}
    else
      {:cont, context}
    end
  end
end