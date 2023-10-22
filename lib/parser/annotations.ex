defmodule SwiftClass.Parser.Annotations do
  alias SwiftClass.Parser.Context
  # Helpers

  if Mix.env() != :prod do
    def context_to_annotation(%Context{} = context, line) do
      [file: context.file, line: line, module: context.module]
    end
  else
    def context_to_annotation(context, line) do
      []
    end
  end
end
