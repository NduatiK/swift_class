defmodule SwiftClass.Helpers.HelperFunctionsTest do
  alias SwiftClass.HelperFunctions
  import NimbleParsec

  defparsec(:helper_functions, HelperFunctions.helper_function(additional: ["to_ime"]))
end
