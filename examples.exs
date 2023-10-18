inspect = fn input ->
  IO.puts("-------------\n")
  IO.inspect(input, label: "input")
  IO.puts("\n")
  result = elem(SwiftClass.parse(input), 1)
  IO.puts(if(is_binary(result), do: result, else: inspect(result)))
end

inspect.("blue")
inspect.("1(.red)")
inspect.("font(Color.largeTitle.)")
inspect.("abc(def: 11, b: [lineWidth: 1lineWidth])")
inspect.("font(.largeTitle) {")


inspect.("font(.)))red)")
inspect.("abc(def: 11, b: [lineWidth: 1lineWidth])")
inspect.("abc(def: 11, b: [lineWidth: a, l: 2a])")