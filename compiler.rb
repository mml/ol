require 'lang'
require 'runtime'

module AST
  module Node
    def immediate?; false; end
    def primcall?; false; end
    def seq?; false; end
    def let?; false; end
    def varref?; false; end
    def if?; false; end
    def prog?; false; end
    def def?; false; end
  end

  class Prog < Struct.new :labels, :expr
    include Node
    def prog?; true; end
  end

  module ImmediateNode
    include Node
    def immediate?; true; end
  end
  class SingletonNode
    include ImmediateNode
  end

  TrueLiteral  = SingletonNode.new
  FalseLiteral = SingletonNode.new
  NilLiteral   = SingletonNode.new

  class Integer < Struct.new :value
    include ImmediateNode
    def immediate?; true; end
  end
  class MethodCall < Struct.new :invocant, :message, :args
    include Node
    def primcall?
      message =~ /^succ|pred|nil\?|zero\?|!|\+|-|==|<|>|<=|>=|\*$/
    end
  end
  class LabelCall < Struct.new :label, :args
    include Node
  end
  class Let < Struct.new :lhs, :rhs, :body
    include Node
    def let?; true; end
  end
  class VarRef < Struct.new :name
    include Node
    def varref?; true; end
  end
  class Seq < Struct.new :exprs
    include Node
    def seq?; true; end
  end
  class If < Struct.new :test, :cons, :alt
    include Node
    def if?; true; end
  end
  class Def < Struct.new :name, :formals, :body
    include Node
    def def?; true; end
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

class LiftProcedure
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

class Compiler
  include Runtime
  @@n = 0

  def initialize( o = STDOUT )
    @out = o
    @parser = ObjLangParser.new
  end

  def compile_program string
    p = LiftProcedure.new.rewrite_program(
      make_prog(@parser.parse(string).exprs))

    p.labels.each {|label,fn|
      emit_label label
      emit_proc fn.formals, fn.body, -4, {}
    }

    # Program body
    emit_label '_ol_entry' # XXX This should probably be a param.
    emit_expr p, -4, {}
    emit 'ret'
  end

  def one
    immediate_rep AST::Integer.new 1
  end

  def zero
    immediate_rep AST::Integer.new 0
  end

  def emit_expr x, si, env
    case
    when x.immediate?
      emit "movl $#{immediate_rep x}, %eax"
    when x.primcall?
      emit_primitive_call x, si, env
    when x.seq?
      x.exprs.each do |e|
        emit_expr e, si, env
      end
    when x.let?
      emit_expr x.rhs, si, env
      emit "movl %eax, #{si}(%esp)"
      nenv = env.merge x.lhs => si
      emit_expr x.body, si - WORD_SIZE, nenv
    when x.varref?
      emit "movl #{env[x.name]}(%esp), %eax"
    when x.if?
      emit_if x.test, x.cons, x.alt, si, env
    when x.prog?
      emit_expr x.expr, si, env
    when x.kind_of?(AST::LabelCall)
      nsi = si - WORD_SIZE
      x.args.each do |arg|
        emit_expr arg, nsi, env
        emit "movl %eax, #{nsi}(%esp)"
        nsi -= WORD_SIZE
      end
      emit "subl $#{-si - WORD_SIZE}, %esp"
      emit "call #{x.label}"
      emit "addl $#{-si - WORD_SIZE}, %esp"
    else
      debugger
      puts 9
    end
  end

  def emit_proc formals, body, si, env
    # This is a bit ugly.  -Matt
    formals.each do |formal|
      env[formal] = si
      si -= 4
    end
    emit_expr body, si, env
    emit 'ret'
  end

  def emit_primitive_call x, si, env
    case x.message
    when 'succ'
      emit_expr x.invocant, si, env
      emit "addl $#{one}, %eax"
    when 'pred'
      emit_expr x.invocant, si, env
      emit "subl $#{one}, %eax"
    when 'nil?'
      emit_expr x.invocant, si, env
      emit_compare "$#{NIL_REP}", 'e'
    when 'zero?'
      emit_expr x.invocant, si, env
      emit_compare "$#{zero}", 'e'
    when '!'
      emit_expr x.invocant, si, env
      emit "xorl $#{1 << BOOL_SHIFT}, %eax"
    when '+'
      emit_expr x.args[0], si, env
      emit "movl %eax, #{si}(%esp)"
      emit_expr x.invocant, si - WORD_SIZE, env
      emit "addl #{si}(%esp), %eax"
    when '-'
      emit_expr x.args[0], si, env
      emit "movl %eax, #{si}(%esp)"
      emit_expr x.invocant, si - WORD_SIZE, env
      emit "subl #{si}(%esp), %eax"
    when '*'
      emit_expr x.args[0], si, env
      emit "movl %eax, #{si}(%esp)"
      emit_expr x.invocant, si - WORD_SIZE, env
      emit "sarl $#{FIXNUM_SHIFT}, %eax"
      emit "imull #{si}(%esp), %eax"
    when '=='
      emit_expr x.args[0], si, env
      emit "movl %eax, #{si}(%esp)"
      emit_expr x.invocant, si - WORD_SIZE, env
      emit_compare "#{si}(%esp)", 'e'
    when '<'
      emit_expr x.args[0], si, env
      emit "movl %eax, #{si}(%esp)"
      emit_expr x.invocant, si - WORD_SIZE, env
      emit_compare "#{si}(%esp)", 'l'
    when '<='
      emit_expr x.args[0], si, env
      emit "movl %eax, #{si}(%esp)"
      emit_expr x.invocant, si - WORD_SIZE, env
      emit_compare "#{si}(%esp)", 'le'
    when '>'
      emit_expr x.args[0], si, env
      emit "movl %eax, #{si}(%esp)"
      emit_expr x.invocant, si - WORD_SIZE, env
      emit_compare "#{si}(%esp)", 'g'
    when '>='
      emit_expr x.args[0], si, env
      emit "movl %eax, #{si}(%esp)"
      emit_expr x.invocant, si - WORD_SIZE, env
      emit_compare "#{si}(%esp)", 'ge'
    end
  end

  def emit_if test, cons, alt, si, env
    l0 = unique_label
    l1 = unique_label
    emit_expr test, si, env
    emit "cmpl $#{immediate_rep AST::FalseLiteral}, %eax"
    emit "je #{l0}"
    emit_expr cons, si, env
    emit "jmp #{l1}"
    emit_label l0
    emit_expr alt, si, env
    emit_label l1
  end

  def unique_label
    @@n += 1
    "__L#{@@n}"
  end

  def emit_label l
    @out.puts "#{l}:"
  end

  def emit_compare rand, flags
    emit "cmpl #{rand}, %eax"
    emit "movl $0, %eax"
    emit "set#{flags} %al"
    emit "sall $#{BOOL_SHIFT}, %eax" # Shift left by 7 bits
    emit "orl $#{BOOL_TAG}, %eax" # Tag as boolean
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
            []
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

  def immediate_rep x
    case x
    when AST::Integer
      x.value << FIXNUM_SHIFT
    when AST::TrueLiteral
      BOOL_TAG | (0b1 << BOOL_SHIFT)
    when AST::FalseLiteral
      BOOL_TAG | (0b0 << BOOL_SHIFT)
    when AST::NilLiteral
      NIL_REP
    end
  end

  def emit s
    @out.puts "\t#{s}"
  end

  def assert condition
    raise "Failed assertion." unless condition
  end
end
