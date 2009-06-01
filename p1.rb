module Compiler
=begin rdoc
Pass 1: FlattenTree

This pass takes the tree produced by the treetop parser and simplifies it by (1)
flattening empty nodes (putting their elements in their place), and (2)
discarding whitespace tokens, except for end-of-statement newlines.
=end
  class FlattenTree
    def process program
      program
    end
  end
end
