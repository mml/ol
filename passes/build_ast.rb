class BuildAST < CompilerPass
  def rewrite_program p
    make_prog p.exprs
  end

  def make_prog pexprs
    AST::Prog.new [], make_seq(pexprs)
  end

  # Given a parse tree, emit an AST.
  def make_seq pexprs
    sexprs = []
    until pexprs.empty?
      a = to_abstract pexprs.shift
      if a.kind_of? Proc
        a = a.call make_seq(pexprs)
        pexprs = []
      end
      sexprs.push a
    end
    AST::Seq.new sexprs
  end

  def to_abstract e
    case e
    when ObjLang::Expr
      to_abstract e.meat
    when ObjLang::AtomicExpr
      if e.chain.empty?
        to_abstract e.base
      else
        messages = e.chain
        messages.elements.reduce(to_abstract(e.base)) do |last,mess|
          AST::MethodCall.new(
            last,
            mess.elements[1].meth.text_value,
            mess.message.param_exprs.map{|pe| to_abstract pe}
          )
        end
      end
    when ObjLang::UnaryOp
      AST::MethodCall.new(
        to_abstract(e.elements[1]),
        e.elements[0].text_value,
        []
      )
    when ObjLang::TrueLiteral
      AST::TrueLiteral
    when ObjLang::FalseLiteral
      AST::FalseLiteral
    when ObjLang::NilLiteral
      AST::NilLiteral
    when ObjLang::Integer
      AST::Integer.new e.text_value.to_i
    when ObjLang::Character
      AST::Integer.new e.chr.text_value[0]
    when ObjLang::OpApp
      AST::MethodCall.new(
        to_abstract(e.rand1.meat),
        e.op.text_value,
        [to_abstract(e.rand2)]
      )
    when ObjLang::Parens
      to_abstract(e.expr)
    when ObjLang::Assignment
      lambda do |body|
        AST::Let.new e.lhs.text_value, to_abstract(e.rhs), body
      end
    when ObjLang::VarRef
      AST::VarRef.new e.text_value
    when ObjLang::IfExpr
      AST::If.new(
        to_abstract(e.test),
        make_seq(e.cons.elements.map &:expr),
        make_seq(e.if_rest.alt.elements.map &:expr)
      )
    when ObjLang::MethDef
      AST::Def.new(
        e.name.text_value,
        e.formal_ids.map(&:text_value),
        make_seq(e.body.elements.map &:expr)
      )
    when ObjLang::Message
      AST::MethodCall.new(
        nil,
        e.meth.text_value,
        e.param_exprs.map {|param| to_abstract param }
      )
    else
      debugger
      raise "Can't translate #{e}\n"
    end
  end
end
