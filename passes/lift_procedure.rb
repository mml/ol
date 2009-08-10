# Pass 3: LiftProcedure
#
# This pass moves all procedure definitions to global labels and replaces calls
# to them with LabelCall forms.  All MethodCall forms are not eliminated,
# however, because we can identify some as primitive calls at this point.
#
# The input to this pass is the output from IdentifyAlloc.  The output adds the
# labels, their definitions, and LabelCall; and removes Def from general
# expression context.
#
# <Prog> ::= Prog {<name> => Def <name> <name>* <Expr>}* <Expr>*
# <Expr> ::= TrueLiteral
#          | FalseLiteral
#          | NilLiteral
#          | Integer <integer>
#          | Let <name> <Expr> <Expr>
#          | VarRef <name>
#          | If <Expr> <Expr> <Expr>
#          | LabelCall <name> <Expr>*
#          | MethodCall <Expr> <name> <Expr>*
#          | Alloc <integer> <integer> <integer>*
#          | Seq <Expr>*

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

