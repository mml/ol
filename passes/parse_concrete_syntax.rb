class ParseConcreteSyntax < CompilerPass
  def rewrite_program p
    tree = ObjLangParser.new.parse(p)
    if nil == tree
      raise "#{p} does not parse!"
    end
    return tree
  end
end
