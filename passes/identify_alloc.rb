class IdentifyAlloc < CompilerPass
  def rewrite_program p
    AST::Prog.new p.labels, (rewrite_expr p.expr)
  end

  def rewrite_expr e
    case e
    when AST::MethodCall
      if e.invocant and e.invocant.varref? and 'Array' == e.invocant.name and 'new' == e.message
        return AST::AllocArray.new
      else
        AST::MethodCall.new(rewrite_expr(e.invocant), e.message, e.args.map{|e| rewrite_expr e})
      end
    when AST::Seq
      AST::Seq.new(e.exprs.map{|e| rewrite_expr e})
    else
      e
    end
  end
end
