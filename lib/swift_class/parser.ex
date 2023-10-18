defmodule SwiftClass.Parser do
  import NimbleParsec

  alias SwiftClass.PostProcessors
  alias __MODULE__
  @whitespace_chars [?\s, ?\t, ?\n, ?\r]

  def unless_matches(list) do
    repeat_until(utf8_char([]), list)
    |> reduce({List, :to_string, []})
  end

  def  non_whitespace(opts \\ []) do
    also_ignore = Keyword.get(opts,:also_ignore, [])

    repeat_until(utf8_char([]), @whitespace_chars ++ also_ignore)
    |> reduce({List, :to_string, []})
  end

  def repeat_until(combinator, matches) do
    repeat_while(combinator, {Parser, :not_match, [matches]})
  end

  def not_match(<<char::utf8, _::binary>>, context, _, _, matches) do
  if char in matches do
      {:halt, context}
    else
      {:cont, context}
    end
  end

  def not_match("", context, _, _, _) do
    {:cont, context}
  end

  def error(opts \\ []) do
    error_range_parser = Keyword.get(opts, :error_range_parser, non_whitespace())
    expected = Keyword.get(opts, :expected, "")
    show_got? = Keyword.get(opts, :show_got?, false)

    error_range_parser
    |> post_traverse({PostProcessors, :throw_unexpected, [expected, show_got?]})
  end

  @one_of_the_following "one of the following:"
  def one_of(start \\ empty(), choices, opts \\ []) do
    prefix = Keyword.get(opts, :prefix, "")

    choices =
      choices
      |> Enum.map(fn
        {combinator, desc} -> {combinator, desc, []}
        other -> other
      end)

    # TODO: Collect information about the depth travelled down each path
    expectation =
      choices
      |> Enum.flat_map(&String.split(elem(&1, 1), "\n"))
      |> Enum.join("\n")
      |> indent(" - ")

    start
    |> concat(
      choice(
        # Enum.map(choices, &strip_one_of_error(elem(&1, 1))) ++
        Enum.map(choices, fn {combinator, _, opts} ->
          if Keyword.get(opts, :unroll_error, true) do
            strip_one_of_error(combinator)
          else
            combinator
          end
        end) ++
          [
            error(
              Keyword.put(opts, :expected, "#{prefix}#{@one_of_the_following}\n#{expectation}\n")
            )
          ]
      )
    )
  end

  def strip_one_of_error({combinator, label}) when is_list(combinator) and is_binary(label) do
    {strip_one_of_error(combinator), label}
  end

  def strip_one_of_error(combinator) when is_list(combinator) do
    Enum.map(combinator, fn part ->
      case part do
        {:choice, args, extra} ->
          case Enum.reverse(args) do
            [
              [
                {:traverse, _, :post,
                 [
                   {NimbleParsec, :__post_traverse__,
                    [
                      {SwiftClass.PostProcessors, :throw_unexpected, _}
                    ]}
                 ]}
              ]
              | other
            ] ->
              {:choice, Enum.reverse(other), extra}

            _ ->
              strip_one_of_error(part)
          end

        _ ->
          strip_one_of_error(part)
      end
    end)
  end

  def strip_one_of_error(other), do: other

  def get_one_of_errors(combinator) do
    case combinator do
      [{:choice, args, _}] ->
        case Enum.reverse(args) do
          [
            [
              {:traverse, _, :post,
               [
                 {NimbleParsec, :__post_traverse__,
                  [{SwiftClass.PostProcessors, :throw_unexpected, [error | _]}]}
               ]}
            ]
            | _
          ] ->
            case error do
              @one_of_the_following <> error ->
                error

              _ ->
                error
            end

          _ ->
            nil
        end

      _ ->
        nil
    end
  end

  def indent(str, indentation \\ "\t") do
    str
    |> String.split("\n")
    |> Enum.map(&(indentation <> &1))
    |> Enum.join("\n")
  end
end
