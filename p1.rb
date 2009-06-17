module Compiler
=begin rdoc
Pass 1: RegularizeTree

This pass makes sure that for all nodes n in the parse tree, n.elements is
always an Enumerable.
=end
  class RegularizeTree
    def self.run program
      if nil == program.elements
        program.elements = []
      elsif !program.elements.is_a? Enumerable
        puts program.elements
        exit
      end

      program.elements.map! {|e| run e}
      program
    end
  end

=begin rdoc
Pass 2: FlattenTree

This pass takes the regularized tree produced by pass 1 and simplifies it by (1)
flattening empty nodes (putting their elements in their place), and (2)
discarding whitespace tokens, except for end-of-statement newlines.
=end
  class FlattenTree
    def self.run program
      program.elements = program.elements.map {|e| flatten e}.reduce([], :concat)
      program
    end

    private

=begin rdoc
flatten takes a node and returns a list of nodes to be substituted in its place.
=end
    def self.flatten node
      if node.empty?
        node.elements.map {|e| flatten e}.reduce([], :concat)
      elsif node.is_a? ObjLang::Whitespace
        []
      else
        node.elements = node.elements.map {|e| flatten e}.reduce([], :concat)
        [node]
      end
    end
  end
end
