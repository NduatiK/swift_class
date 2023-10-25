defmodule SwiftClassTest do
  use ExUnit.Case
  doctest SwiftClass
  alias SwiftClass.Helpers.HelperFunctionsTest

  def parse(input) do
    SwiftClass.parse(input, content: [file: __ENV__.file])
  end

  def parse2(input) do
    SwiftClass.parse(input, content: [file: __ENV__.file])
  end

 

  describe "benchmark" do
    test "parse long stylesheet" do
      file_name = "test/helpers/classes.swiftui.style"
      file = File.read!(file_name)

      for _ <- 1..100 do
        file
        |> SwiftClass.parse_class_block(file: file_name)
      end
    end
  end

  describe "parse/1" do
    test "parses modifier function definition" do
      input = "bold(true)"
      output = {:bold, [], [true]}

      assert parse(input) == output
    end

    test "parses modifier with multiple arguments" do
      input = "background(\"foo\", \"bar\")"
      output = {:background, [], ["foo", "bar"]}

      assert parse(input) == output

      # space at start and end
      input = "background( \"foo\", \"bar\" )"
      assert parse(input) == output

      # space at start only
      input = "background( \"foo\", \"bar\")"
      assert parse(input) == output

      # space at end only
      input = "background(\"foo\", \"bar\" )"
      assert parse(input) == output
    end

    test "parses single modifier with atom as IME" do
      input = "font(.largeTitle)"

      output = {:font, [], [{:., [], [nil, :largeTitle]}]}

      assert parse(input) == output
    end

    test "parses chained IMEs" do
      input = "font(color: Color.red)"

      output = {:font, [], [[color: {:., [], [:Color, :red]}]]}

      assert parse(input) == output

      input = "font(color: Color.red.shadow(.thick))"

      output =
        {:font, [],
         [[color: {:., [], [:Color, {:., [], [:red, {:shadow, [], [{:., [], [nil, :thick]}]}]}]}]]}

      assert parse(input) == output
    end

    test "parses multiple modifiers" do
      input = "font(.largeTitle) bold(true) italic(true)"

      output = [
        {:font, [], [{:., [], [nil, :largeTitle]}]},
        {:bold, [], [true]},
        {:italic, [], [true]}
      ]

      assert parse(input) == output
    end

    test "parses complex modifier chains" do
      input = "color(color: .foo.bar.baz(1, 2).qux)"

      output =
        {:color, [],
         [
           [
             color:
               {:., [],
                [nil, {:., [], [:foo, {:., [], [:bar, {:., [], [{:baz, [], [1, 2]}, :qux]}]}]}]}
           ]
         ]}

      assert parse(input) == output
    end

    test "parses multiline" do
      input = """
      font(.largeTitle)
      bold(true)
      italic(true)
      """

      output = [
        {:font, [], [{:., [], [nil, :largeTitle]}]},
        {:bold, [], [true]},
        {:italic, [], [true]}
      ]

      assert parse(input) == output
    end

    test "parses string literal value type" do
      input = "foo(\"bar\")"
      output = {:foo, [], ["bar"]}

      assert parse(input) == output
    end

    test "parses numerical types" do
      input = "foo(1, -1, 1.1)"
      output = {:foo, [], [1, -1, 1.1]}

      assert parse(input) == output
    end

    test "parses key/value pairs" do
      input = ~s|foo(bar: "baz", qux: .quux)|
      output = {:foo, [], [[bar: "baz", qux: {:., [], [nil, :quux]}]]}

      assert parse(input) == output
    end

    test "parses bool and nil values" do
      input = "foo(true, false, nil)"
      output = {:foo, [], [true, false, nil]}

      assert parse(input) == output
    end

    test "parses Implicit Member Expressions" do
      input = "color(.red)"
      output = {:color, [], [{:., [], [nil, :red]}]}

      assert parse(input) == output
    end

    test "parses nested function calls" do
      input = ~s|foo(bar("baz"))|
      output = {:foo, [], [{:bar, [], ["baz"]}]}

      assert parse(input) == output
    end

    test "parses attr value references" do
      input = ~s|foo(attr("bar"))|
      output = {:foo, [], [{:__attr__, [], "bar"}]}

      assert parse(input) == output
    end
  end

  describe "class block parser" do
    test "parses a simple block" do
      input = """
      "red-header" do
        color(.red)
        font(.largeTitle)
      end
      """

      output = [
        {
          ["red-header", {:_target, [], Elixir}],
          [
            {:color, [], [{:., [], [nil, :red]}]},
            {:font, [], [{:., [], [nil, :largeTitle]}]}
          ]
        }
      ]

      assert SwiftClass.parse_class_block(input) == output
    end

    test "parses a complex block" do
      input = """
      "color-" <> color_name do
        foo(true)
        color(color_name)
        bar(false)
      end
      """

      output = [
        {[
           {:<>, [context: Elixir, imports: [{2, Kernel}]],
            ["color-", {:color_name, [], Elixir}]},
           {:_target, [], Elixir}
         ],
         [
           {:foo, [], [true]},
           {:color, [], [{:color_name, [], Elixir}]},
           {:bar, [], [false]}
         ]}
      ]

      assert SwiftClass.parse_class_block(input) == output
    end

    test "parses a complex block (2)" do
      input = """
      "color-" <> color do
        color(color)
      end
      """

      output = [
        {[
           {:<>, [context: Elixir, imports: [{2, Kernel}]], ["color-", {:color, [], Elixir}]},
           {:_target, [], Elixir}
         ], [{:color, [], [{:color, [], Elixir}]}]}
      ]

      assert SwiftClass.parse_class_block(input) == output
    end

    test "parses multiple blocks" do
      input = """
      "color-" <> color_name do
        foo(true)
        color(color_name)
        bar(false)
      end

      "color-red" do
        color(.red)
      end
      """

      output = [
        {[
           {:<>, [context: Elixir, imports: [{2, Kernel}]],
            ["color-", {:color_name, [], Elixir}]},
           {:_target, [], Elixir}
         ],
         [
           {:foo, [], [true]},
           {:color, [], [{:color_name, [], Elixir}]},
           {:bar, [], [false]}
         ]},
        {
          ["color-red", {:_target, [], Elixir}],
          [{:color, [], [{:., [], [nil, :red]}]}]
        }
      ]

      assert SwiftClass.parse_class_block(input) == output
    end

    test "can take optional target in definition" do
      input = """
        "color-red", target: :watchos do
          color(.red)
        end
      """

      output = [
        {
          ["color-red", [target: :watchos]],
          [{:color, [], [{:., [], [nil, :red]}]}]
        }
      ]

      assert SwiftClass.parse_class_block(input) == output
    end
  end

  describe "helper functions" do
    test "to_atom" do
      input = "buttonStyle(style: to_atom(style))"

      output = {:buttonStyle, [], [[style: {Elixir, [], {:to_atom, [], [{:style, [], Elixir}]}}]]}

      assert parse(input) == output
    end

    test "to_integer" do
      input = "frame(height: to_integer(height))"

      output = {:frame, [], [[height: {Elixir, [], {:to_integer, [], [{:height, [], Elixir}]}}]]}

      assert parse(input) == output
    end

    test "to_float" do
      input = "kerning(kerning: to_float(kerning))"

      output =
        {:kerning, [], [[kerning: {Elixir, [], {:to_float, [], [{:kerning, [], Elixir}]}}]]}

      assert parse(input) == output
    end

    test "to_boolean" do
      input = "hidden(to_boolean(is_hidden))"

      output = {:hidden, [], [{Elixir, [], {:to_boolean, [], [{:is_hidden, [], Elixir}]}}]}

      assert parse(input) == output
    end

    test "camelize" do
      input = "font(family: camelize(family))"

      output = {:font, [], [[family: {Elixir, [], {:camelize, [], [{:family, [], Elixir}]}}]]}

      assert parse(input) == output
    end

    test "underscore" do
      input = "font(family: underscore(family))"

      output = {:font, [], [[family: {Elixir, [], {:underscore, [], [{:family, [], Elixir}]}}]]}

      assert parse(input) == output
    end

    test "additional helper function names can be provided" do
      input = "to_ime(family)"

      output = {Elixir, [], {:to_ime, [], [{:family, [], Elixir}]}}

      assert {:ok, [result], _, _, _, _} = HelperFunctionsTest.helper_functions(input)
      assert result == output
    end

    test "can't parse unknown helper functions" do
      input = "to_unknown(family)"

      assert {:error, "expected a 1-arity helper function (to_atom, " <> _, _, _, _, _} =
               HelperFunctionsTest.helper_functions(input)
    end
  end

  describe "error reporting" do
    setup do
      # Disable ANSI so we don't have to worry about colors
      Application.put_env(:elixir, :ansi_enabled, false)
      on_exit(fn -> Application.put_env(:elixir, :ansi_enabled, true) end)
    end

    test "ANSI is off" do
      assert "message" == IO.iodata_to_binary(IO.ANSI.format([:blue, "message"]))
    end

    test "modifier without brackets" do
      input = "blue"

      # assert_raise SyntaxError, ~r/^today's lucky number is 0\.\d+!$/, fn ->
      error =
        assert_raise SyntaxError, fn ->
          parse2(input)
        end

      assert """
             Unsupported input:
               |
             1 | blue_
               |
               |
             """ <> _ = error.description
    end

    test "invalid modifier name" do
      input = "1(.red)"

      error =
        assert_raise SyntaxError, fn ->
          parse2(input)
        end
    end

    test "invalid modifier argument" do
      input = "font(Color.largeTitle.)"

      error =
        assert_raise SyntaxError, fn ->
          parse2(input)
        end
    end

    test "invalid modifier argument2" do
      input = "abc(11, 2a)"

      error =
        assert_raise SyntaxError, fn ->
          parse2(input)
        end
    end

    test "invalid keyword pair: missing colon" do
      input = "abc(def: 11, b: [lineWidth a, l: 2a]"

      error =
        assert_raise SyntaxError, fn ->
          parse2(input)
        end
    end

    test "invalid keyword pair: invalid value" do
      input = "abc(def: 11, b: [lineWidth: 1lineWidth])"

      error =
        assert_raise SyntaxError, fn ->
          parse2(input)
        end
    end

    test "unexpected trailing character" do
      input = "font(.largeTitle) {"

      error =
        assert_raise SyntaxError, fn ->
          parse2(input)
        end
    end

    test "unexpected bracket" do
      input = "font(.)red)"

      error =
        assert_raise SyntaxError, fn ->
          parse2(input)
        end
    end
  end
end
