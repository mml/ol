class LiftProcedure < CompilerPass
  def rewrite_program p
    labels, expr = rewrite_expr p.expr
    AST::Prog.new labels, expr
  end

  # Given an expr, returns a rewritten expr and a hash of label,def pairs
  def rewrite_expr e
    case e
    when AST::Def
      labels, body = rewrite_expr e.body
      return  labels.merge(e.name => AST::Def.new(e.name, e.formals, body)),
              AST::NilLiteral
    when AST::MethodCall
      # XXX Ignoring the invocant for now.
      if e.primcall?
        labels, invocant = rewrite_expr e.invocant
      else
        labels = {}
      end
      labelses, args = e.args.map2 {|arg| rewrite_expr arg}
      labels = labelses.reduce(labels, &:merge)
      # XXX This semantic check probably belongs up when we build the AST.
      if e.primcall?
        return  labels, AST::MethodCall.new(invocant, e.message, args)
      else
        return  labels, AST::LabelCall.new(e.message, args)
      end
    when AST::Let
      rhs_labels, rhs = rewrite_expr e.rhs
      body_labels, body = rewrite_expr e.body
      return  rhs_labels.merge(body_labels),
              AST::Let.new(e.lhs, rhs, body)
    when AST::Seq
      labelses, exprs = e.exprs.map2 {|expr| rewrite_expr expr}
      return  labelses.reduce({}, &:merge),
              AST::Seq.new(exprs)
    when AST::If
      test_labels, test = rewrite_expr e.test
      cons_labels, cons = rewrite_expr e.cons
      alt_labels, alt   = rewrite_expr e.alt
      return  test_labels.merge(cons_labels).merge(alt_labels),
              AST::If.new(test, cons, alt)
    when AST::ImmediateNode, AST::VarRef
      return {}, e
    when AST::Node
      return {}, e
    else
      debugger
    end
  end
end

class Array
  def map2
    as,bs = [],[]
    each do |elt|
      a,b = yield elt
      as.push a
      bs.push b
    end
    return as, bs
  end
end

