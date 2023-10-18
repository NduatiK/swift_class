defmodule SwiftClass.PostProcessors do
  # Error Parsing
  def prepare_context(rest, args, context, {_line, _offset}, _byte_binary_offset) do
    {rest, args,
     context
     |> Map.put_new(:line, %{})
     |> Map.put_new(:source, rest)}
  end

  def set_context(rest, args, context, {line, _offset}, _byte_offset, {k, v}) do
    {rest, args, put_in(context, [k], v)}
  end

  def mark_line(rest, args, context, {line, _offset}, _byte_offset, name) do
    {rest, args, put_in(context, [:line, name], line)}
  end

  def unmark_line(rest, args, context, {_line, _offset}, _byte_offset, name) do
    {rest, args, put_in(context, [:line, name], nil)}
  end

  def throw_unexpected(
        rest,
        [selected],
        context,
        {line, _offset},
        byte_offset,
        expectation,
        show_got?
      ) do
    source_line = (context[:source_line] || 1) + line - 1
    line_number = "#{source_line}"
    line_spacer = String.duplicate(" ", String.length(line_number))

    error_text_length = String.length(selected)

    before = String.slice(context[:source], 0, max(0, byte_offset - error_text_length))
    middle = String.slice(context[:source], byte_offset - error_text_length, error_text_length)
    after_ = String.slice(context[:source], byte_offset..-1//1)

    source_lines =
      [
        before,
        IO.ANSI.format([:red, middle]),
        case {after_, middle} do
          {"", ""} ->
            IO.ANSI.format([:red, "_"])

          _ ->
            after_
        end
      ]
      |> IO.iodata_to_binary()
      |> String.split("\n")
      |> List.to_tuple()

    maybe_but_got =
      if show_got? do
        ", but got ‘#{selected}’"
      else
        ""
      end

    {:error,
     """
     #{context[:file] || ""}:#{source_line}: error:
         Not valid: ‘#{selected}’
         The parser does not support the following:
     #{line_spacer} |
     #{line_number} | #{elem(source_lines, line - 1)}
     #{line_spacer} |

     Expected #{expectation}#{maybe_but_got}
     """
     |> String.trim()}
  end

  # PostProcessors
  def to_attr_ast(rest, [[attr], "attr"], context, {_line, _offset}, _binary_offset)
      when is_binary(attr) do
    {rest, [{:__attr__, [], attr}], context}
  end

  def wrap_in_tuple(rest, args, context, {_line, _offset}, _binary_offset) do
    {rest, [List.to_tuple(Enum.reverse(args))], context}
  end

  def block_open_with_variable_to_ast(
        rest,
        [variable, string],
        context,
        {_line, _offset},
        _binary_offset
      ) do
    {rest,
     [
       {:<>, [context: Elixir, imports: [{2, Kernel}]], [string, variable]}
     ], context}
  end

  def tag_as_elixir_code(rest, [quotable], context, {_line, _offset}, _binary_offset) do
    {rest, [{Elixir, [], quotable}], context}
  end

  def to_elixir_variable_ast(rest, [variable_name], context, {_line, _offset}, _binary_offset) do
    {rest, [{String.to_atom(variable_name), [], Elixir}], context}
  end

  def to_implicit_ime_ast(
        rest,
        [[], variable_name],
        context,
        {_line, _offset},
        _binary_offset,
        _is_initial = true
      ) do
    {rest, [{:., [], [nil, String.to_atom(variable_name)]}], context}
  end

  def to_implicit_ime_ast(
        rest,
        [args, variable_name],
        context,
        {_line, _offset},
        _binary_offset,
        _is_initial = true
      ) do
    {rest, [{:., [], [nil, {String.to_atom(variable_name), [], args}]}], context}
  end

  def to_implicit_ime_ast(
        rest,
        [[], variable_name],
        context,
        {_line, _offset},
        _binary_offset,
        false
      ) do
    # IO.inspect(sections, label: "chain_ast_after")

    {rest, [String.to_atom(variable_name)], context}
  end

  def to_implicit_ime_ast(
        rest,
        [args, variable_name],
        context,
        {_line, _offset},
        _binary_offset,
        false
      ) do
    # IO.inspect(sections, label: "chain_ast_after")

    {rest, [{String.to_atom(variable_name), [], args}], context}
  end

  def to_scoped_ime_ast(
        rest,
        [[] = _args, variable_name, scope],
        context,
        {_line, _offset},
        _binary_offset
      ) do
    {rest, [String.to_atom(variable_name), String.to_atom(scope)], context}
  end

  def to_scoped_ime_ast(
        rest,
        [args, variable_name, scope],
        context,
        {_line, _offset},
        _binary_offset
      ) do
    {rest, [{String.to_atom(variable_name), [], args}, String.to_atom(scope)], context}
  end

  defp combine_chain_ast_parts({:., [], [nil, atom]}, inner) when is_atom(atom) do
    {:., [], [nil, {:., [], [atom, inner]}]}
  end

  defp combine_chain_ast_parts(outer, inner) do
    {:., [], [outer, inner]}
  end

  def chain_ast(rest, sections, context, {_line, _offset}, _binary_offset) do
    sections = Enum.reduce(sections, &combine_chain_ast_parts/2)

    {rest, [sections], context}
  end

  def to_function_call_ast(rest, args, context, {_line, _offset}, _binary_offset) do
    [ast_name | other_args] = Enum.reverse(args)

    {rest, [{String.to_atom(ast_name), [], other_args}], context}
  end

  def to_keyword_tuple_ast(rest, [arg1, arg2], context, {_line, _offset}, _binary_offset) do
    {rest, [{String.to_atom(arg2), arg1}], context}
  end

  def tag_as_content(rest, [content], context, {_line, _offset}, _binary_offset) do
    {rest, [content: content], context}
  end

  def tag_as_content(rest, content, context, {_line, _offset}, _binary_offset) do
    {rest, [content: Enum.reverse(content)], context}
  end

  def block_open_to_ast(rest, [class_name], context, {_line, _offset}, _binary_offset) do
    {rest, [[class_name, {:_target, [], Elixir}]], context}
  end

  def block_open_to_ast(
        rest,
        [key_value_pairs, class_name],
        context,
        {_line, _offset},
        _binary_offset
      ) do
    {rest, [[class_name, key_value_pairs]], context}
  end
end
