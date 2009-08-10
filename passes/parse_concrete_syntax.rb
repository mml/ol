# Pass 0: ParseConcreteSyntax
#
# This pass takes a raw program as a string and parses it, producing a raw parse
# tree.  The form of this tree is dictated by the parser.
#
# The input to this pass is the language defined in the file ol.treetop.  The
# output is also specified by that file and the classes in lib/lang.rb.
class ParseConcreteSyntax < CompilerPass
  def rewrite_program p
    tree = ObjLangParser.new.parse(p)
    if nil == tree
      raise "#{p} does not parse!"
    end
    return tree
  end
end
