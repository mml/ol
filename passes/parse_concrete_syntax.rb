class ParseConcreteSyntax < CompilerPass
  def rewrite_program p
    ObjLangParser.new.parse(p)
  end
end
