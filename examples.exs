inspect = fn input, line ->
  # IO.puts("-------------\n")
  # IO.inspect(input, label: "input")
  IO.puts("\n")
  result = elem(SwiftClass.parse(input, [context: [file: __ENV__.file, source_line: line]]), 1)
  IO.puts(if(is_binary(result), do: result, else: inspect(result)))
end
inspect.("abc(def: 11, b: [lineWidth a, l: 2a]", __ENV__.line)

inspect.("blue", __ENV__.line)
inspect.("1(.red)", __ENV__.line)
inspect.("font(Color.largeTitle.)", __ENV__.line)
inspect.("abc(def: 11, b: [lineWidth: 1lineWidth])", __ENV__.line)
inspect.("font(.largeTitle) {", __ENV__.line)


inspect.("font(.)))red)", __ENV__.line)
inspect.("abc(def: 11, b: [lineWidth: 1lineWidth])", __ENV__.line)
inspect.("abc(def: 11, b: [lineWidth: a, l: 2a])", __ENV__.line)