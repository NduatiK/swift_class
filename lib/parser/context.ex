defmodule SwiftClass.Parser.Context do
  alias __MODULE__

  defstruct source: "",
            errors: [],
            file: "",
            # Where in the code does the input start?
            # Useful for localizing errors when parsing sigil text
            source_line: 1,
            # When freezes is greater than 0, do not accept errors
            freezes: 0

  def prepare_context(rest, args, context, {_line, _offset}, _byte_binary_offset) do
    {rest, args,
     Map.put_new(context, :context, %Context{
       source: rest,
       file: context[:file] || "",
       source_line: context[:source_line] || 1
     })}
  end

  def is_frozen?(%Context{freezes: freezes}), do: freezes > 0
  def is_frozen?(%{context: %Context{freezes: freezes}}), do: freezes > 0
  def has_error?(%Context{errors: errors}), do: errors != []
  def has_error?(%{context: %Context{errors: errors}}), do: errors != []

  def put_new_error(context, rest, error) do
    # IO.inspect({"put_new_error", is_frozen?(context), rest, error})

    if is_frozen?(context) and not error.forced? do
      # IO.inspect({error}, label: "frozen")
      context
    else
      # IO.inspect({error}, label: "new_error")
      path = [:context, Access.key(:errors)]

      {_, context} =
        get_and_update_in(context, path, fn
          existing_errors -> {[error | existing_errors], [error | existing_errors]}
        end)

      context
    end
  end

  def freeze_context(rest, args, context, {_line, _offset}, _byte_binary_offset) do
    # IO.inspect("freeze_context")
    {_, context} = get_and_update_in(context, [:context, Access.key(:freezes)], &{&1, &1 + 1})
    {rest, args, context}
  end

  def unfreeze_context(rest, args, context, {_line, _offset}, _byte_binary_offset) do
    # IO.inspect("unfreeze_context")

    {_, context} =
      get_and_update_in(context, [:context, Access.key(:freezes)], &{&1, max(0, &1 - 1)})

    {rest, args, context}
  end
end
