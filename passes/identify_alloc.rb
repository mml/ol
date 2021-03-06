# Pass 3: IdentifyAlloc
#
# This pass identifies calls to 'Array.new()' and converts them to explicit heap
# allocation operations.
#
# The input to this pass is the same as the output from
# SpecifyImmediateRepresentation.  The output just has the Alloc() form added
#
# <Prog> ::= Prog <Expr>*
# <Expr> ::= <integer>
#          | Let <name> <Expr> <Expr>
#          | VarRef <name>
#          | If <Expr> <Expr> <Expr>
#          | Def <name> <name>* <Expr>
#          | MethodCall <Expr> <name> <Expr>*
#          | Alloc <integer> <integer> <integer>*
#          | Seq <Expr>*

class IdentifyAlloc < CompilerPass
  include Runtime
  def rewrite_program p
    AST::Prog.new p.labels, (rewrite_expr p.expr)
  end

  def rewrite_expr e
    case e
    when AST::MethodCall
      if e.invocant and e.invocant.kind_of?(AST::VarRef) and 'Array' == e.invocant.name and 'new' == e.message
        AST::Alloc.new(32 * WORD_SIZE, ARRAY_TAG, [30, 0]) # Set capacity to 30 and count to 0
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
