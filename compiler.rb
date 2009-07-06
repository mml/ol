require 'lang'

module AST
  # TODO: give all of these some shared methods like 'primcall?', 'assignment?',
  # etc.
  TrueLiteral  = :true
  FalseLiteral = :false
  NilLiteral   = :nil
  Integer      = Struct.new :value
  MethodCall   = Struct.new :invocant, :message, :args
  Let          = Struct.new :lhs, :rhs, :body
  VarRef       = Struct.new :name
  Seq          = Struct.new :exprs
end

class Env
  def initialize *args
    if args.empty?
      @env = {}
    else
      @env = args[0]
    end
  end

  def extend hash
    nenv = Env.new @env.clone
    hash.each do |k,v|
      nenv.env[k] = v
    end
    nenv
  end

  def [] k
    @env[k]
  end

  protected
  attr_accessor :env
end

class Compiler
  BOOL_TAG  = 0b0011_1110
  NIL_REP   = 0b0010_1111
  WORD_SIZE = 4
  FIXNUM_SHIFT = 2

  def initialize( o = STDOUT )
    @out = o
    @parser = ObjLangParser.new
  end

  def compile_program string
    expr = make_ast(@parser.parse(string).exprs)
    emit_expr expr, -4, Env.new
    emit 'ret'
  end

  def one
    immediate_rep AST::Integer.new 1
  end

  def zero
    immediate_rep AST::Integer.new 0
  end

  def emit_expr x, si, env
    if immediate? x
      emit "movl $#{immediate_rep x}, %eax"
    elsif primcall? x
      emit_primitive_call x, si, env
    elsif x.kind_of? AST::Seq
      x.exprs.each do |e|
        emit_expr e, si, env
      end
    elsif x.kind_of? AST::Let
      emit_expr x.rhs, si, env
      emit "movl %eax, #{si}(%esp)"
      nenv = env.extend x.lhs => si
      emit_expr x.body, si - WORD_SIZE, nenv
    elsif x.kind_of? AST::VarRef
      emit "movl #{env[x.name]}(%esp), %eax"
    else
      debugger
      puts 9
    end
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
      emit "xorl $1, %eax"
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

  def emit_compare rand, flags
    emit "cmpl #{rand}, %eax"
    emit "movl $0, %eax"
    emit "set#{flags} %al"
    #emit "sall $7, %eax" # Shift left by 7 bits
    emit "orl $#{BOOL_TAG}, %eax" # Tag as boolean
  end

  # Given a parse tree, emit an AST.
  def make_ast top
    exprs = []
    until top.empty?
      a = to_abstract top.shift
      if a.kind_of? Proc
        a = a.call make_ast(top)
        top = []
      end
      exprs.push a
    end
    AST::Seq.new exprs
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
    else
      debugger
      raise "Can't translate #{e}\n"
    end
  end

  def immediate? x
    case x
    when AST::Integer, AST::TrueLiteral, AST::FalseLiteral, AST::NilLiteral
      true
    else
      false
    end
  end

  def primcall? x
    case x
    when AST::MethodCall; x.message =~ /^succ|pred|nil\?|zero\?|!|\+|-|==|<|>|<=|>=|\*$/
    else;                 false
    end
  end

  def immediate_rep x
    case x
    when AST::Integer
      x.value << 2
    when AST::TrueLiteral
      BOOL_TAG | 0b1 # FIXME: I think I'm setting the wrong bit.
    when AST::FalseLiteral
      BOOL_TAG | 0b0
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
