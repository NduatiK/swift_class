defmodule SwiftClass.Modifiers do
  import SwiftClass.Tokens
  alias SwiftClass.PostProcessors
  import SwiftClass.HelperFunctions
  import NimbleParsec
  import SwiftClass.Parser

  defparsec(
    :key_value_list,
    enclosed("[", key_value_pairs(), "]"),
    export_combinator: true
  )

  # .baz
  # .baz(0.1)
  implicit_ime = fn is_initial ->
    ignore(string("."))
    |> concat(word())
    |> wrap(optional(parsec(:brackets)))
    |> post_traverse({PostProcessors, :to_implicit_ime_ast, [is_initial]})
  end

  # Foo.bar
  # Foo.baz(0.1)
  scoped_ime =
    module_name()
    |> ignore(string("."))
    |> concat(word())
    |> wrap(optional(parsec(:brackets)))
    |> post_traverse({PostProcessors, :to_scoped_ime_ast, []})

  defparsec(
    :ime,
    one_of([
      # Scoped
      # 
      {scoped_ime, "scoped IME like `Color.red`"},
      # Implicit
      # .red
      {implicit_ime.(true), "implicit IME like `.red`"}
    ])
    |> choice([
      repeat(
        lookahead(string("."))
        |> one_of([
          # <other_ime>.red
          {implicit_ime.(false), "<other_ime>.red"}
        ])
      ),
      lookahead_not(string("."))
      |> concat(empty())
    ])
    |> post_traverse({PostProcessors, :chain_ast, []}),
    export_combinator: true
  )

  defparsec(
    :nested_attribute,
    choice([
      #
      string("attr")
      |> wrap(parsec(:brackets))
      |> post_traverse({PostProcessors, :to_attr_ast, []}),
      #
      helper_function(),
      #
      word()
      |> parsec(:brackets)
      |> post_traverse({PostProcessors, :to_function_call_ast, []})
    ]),
    export_combinator: true
  )

  @bracket_child [
    {literal(), ~s'a number, string, nil, boolean or :atom'},
    {key_value_pairs(),
     ~s'a list of keyword pairs eg ‘style: :dashed’, ‘size: 12’ or  ‘style: [lineWidth: 1]’'},
    {parsec(:nested_attribute), ~s'a modifier eg ‘foo(bar())’'},
    {parsec(:ime), ~s'an IME eg ‘Color.red’ or ‘.largeTitle’ or ‘Color.to_ime(variable)’'},
    {variable(), ~s|a variable defined in the class header eg ‘color_name’|}
  ]

  defparsec(
    :brackets,
    enclosed("(", comma_separated_list(one_of(@bracket_child)), ")")
  )

  content =
    one_of(
      empty(),
      [
        {enclosed("[", comma_separated_list(one_of(@bracket_child)), "]"),
         "a comma separated list of modifiers"},
        #
        {newline_separated_list(one_of(@bracket_child)), "a newline-separated list of modifiers"},
        #
        {one_of(@bracket_child), "a single modifier"}
      ],
      prefix: "content in the form ‘<modifier> { <content> }’ where <content> is "
    )
    |> post_traverse({PostProcessors, :tag_as_content, []})
    |> wrap()

  defparsec(
    :modifier,
    ignore_whitespace()
    |> concat(modifier_name())
    |> parsec(:brackets)
    |> enclosed("{", content, "}", optional: true)
    |> post_traverse({PostProcessors, :to_function_call_ast, []}),
    export_combinator: true
  )

  defparsec(
    :modifiers,
    start()
    |> times(parsec(:modifier), min: 1)
    |> eos(),
    export_combinator: true
  )

  pair =
    ignore(word())
    |> concat(ignore(string(":")))
    |> ignore(whitespace(min: 1))
    |> choice(
      Enum.map(key_value_children(), &ignore(strip_one_of_error(elem(&1, 0)))) ++
        [
          non_whitespace(at: "error", also_ignore: [?], ?,])
          |> post_traverse({PostProcessors, :set_context, [{:found_error?, true}]})
        ]
    )

  defparsec(
    :key_value_list_error,
    ignore(string("["))
    |> concat(pair)
    |> repeat_while(
      ignore_whitespace()
      |> ignore(string(","))
      |> ignore_whitespace()
      |> concat(pair),
      {:not_found_error, []}
    )
    |> map({List, :wrap, []})
    |> map({List, :flatten, []})
    |> map({Kernel, :hd, []})
    |> post_traverse({PostProcessors, :set_context, [{:found_error?, false}]}),
    export_combinator: true
  )

  def not_found_error(_, %{found_error?: true} = context, _, _) do
    {:halt, context}
  end

  def not_found_error(_, context, _, _) do
    {:cont, context}
  end
end
