# input = "font(.largeTitle) bold italic"
# # output = [["font", [".largeTitle"], nil], ["bold", [true], nil], ["italic", [true], nil]]

# input = "font(.largeTitle) bold italic margin-4"
# output = [["font", [".largeTitle"], nil], ["bold", [true], nil], ["italic", [true], nil]]

# SwiftClass.parse(input)

inspect = fn result ->
  result = elem(result, 1)
  IO.puts(if(is_binary(result), do: result, else: inspect(result)))
end

inspect.(SwiftClass.parse("font(Color.largeTitle.)"))
inspect.(SwiftClass.parse("abc(def: 11, b: [lineWidth: 1lineWidth])"))


# Haskell errors look like this:

# lib/Bot/Qoda/Task/MemPoolListener.hs:113:20: error:
#     Not in scope: ‘API.Network.getNewestBlockNumbers’
#     Perhaps you meant one of these:
#       ‘API.Network.getNewestBlockNumber’ (imported from Qoda.Network.Ethereum.API.Network),
#       ‘API.Network.getNewestBlock’ (imported from Qoda.Network.Ethereum.API.Network)
#     Module ‘Qoda.Network.Ethereum.API.Network’ does not export ‘getNewestBlockNumbers’.
#     |
# 113 |     _ <- Task.lift API.Network.getNewestBlockNumbers
#     |                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# I would like 

# .../sheet.ex:113: error:
#     Not valid: ‘Color.largeTitle.’
#     Perhaps you meant one of these:
#       ‘Color.largeTitle’,                  <- From what was parsed successfully
#     The SwiftUI class parser does not support ‘Color.largeTitle’.
#    |
# 10 |    font(Color.largeTitle.)
#    |         ^^^^^^^^^^^^^^^^^