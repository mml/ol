# Pass 2: SpecifyImmediateRepresentation
#
# This pass replaces all constant values with their runtime representation as
# integers.  The input to this pass is the output from BuildAST.  The
# output has removed all the *Literal forms and replaced them with integers:
#
# <Prog> ::= Prog <Expr>*
# <Expr> ::= <integer>
#          | Let <name> <Expr> <Expr>
#          | VarRef <name>
#          | If <Expr> <Expr> <Expr>
#          | Def <name> <name>* <Expr>
#          | MethodCall <Expr> <name> <Expr>*
#          | Seq <Expr>*

class SpecifyImmediateRepresentation < CompilerPass
  include Runtime
  def rewrite_program p
    AST::Prog.new(p.labels, rewrite_expr(p.expr))
  end

  def rewrite_expr e
    case e
    when NilClass # unspecified invocant
      e
    when AST::TrueLiteral
      TRUE_REP
    when AST::FalseLiteral
      FALSE_REP
    when AST::NilLiteral
      NIL_REP
    when AST::Integer
      e.value << FIXNUM_SHIFT
    when AST::Let
      AST::Let.new(e.lhs, rewrite_expr(e.rhs), rewrite_expr(e.body))
    when AST::VarRef
      e
    when AST::If
      AST::If.new(rewrite_expr(e.test), rewrite_expr(e.cons), rewrite_expr(e.alt))
    when AST::Def
      AST::Def.new(e.name, e.formals, rewrite_expr(e.body))
    when AST::MethodCall
      AST::MethodCall.new(rewrite_expr(e.invocant),
                          e.message,
                          e.args.map{|arg| rewrite_expr(arg)})
    when AST::Seq
      AST::Seq.new(e.exprs.map{|expr| rewrite_expr(expr)})
    else
      raise "WTF? ->#{e}<- #{e.class}"
    end
  end
end
