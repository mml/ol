require 'lang'

module AST
  Statement    = Struct.new :expr
  TrueLiteral  = :true
  FalseLiteral = :false
  NilLiteral   = :nil
  Integer      = Struct.new :value
  MethodCall   = Struct.new :invocant, :message, :args
end

class Compiler
  BOOL_TAG  = 0b0011_1110
  NIL_REP   = 0b0010_1111
  WORD_SIZE = 4

  def initialize( o = STDOUT )
    @out = o
    @parser = ObjLangParser.new
  end

  def compile_program string
    stmts = make_ast(@parser.parse(string))
    if stmts.length > 1
      raise 'Too many statements.'
    end
    emit_expr stmts[0].expr
    emit "ret"
  end

  def one
    immediate_rep AST::Integer.new 1
  end

  def zero
    immediate_rep AST::Integer.new 0
  end

  def emit_expr x
    if immediate? x
      emit "movl $#{immediate_rep x}, %eax"
    elsif primcall? x
      emit_primitive_call x
    end
  end

  def emit_primitive_call x
    case x.message
    when 'succ'
      emit_expr x.invocant
      emit "addl $#{one}, %eax"
    when 'pred'
      emit_expr x.invocant
      emit "subl $#{one}, %eax"
    when 'nil?'
      emit_expr x.invocant
      emit "cmpl $#{NIL_REP}, %eax" # Compare EAX to nil
      emit "movl $0, %eax" # Clear EAX (=> AL)
      emit "sete %al"      # AL = 1 if the same, 0 if not
      #emit "sall $7, %eax" # Shift left by 7 bits
      emit "orl $#{BOOL_TAG}, %eax" # Tag as boolean
    when 'zero?'
      emit_expr x.invocant
      emit "cmpl $#{zero}, %eax" # Compare EAX to 0
      emit "movl $0, %eax" # Clear EAX (=> AL)
      emit "sete %al"      # AL = 1 if the same, 0 if not
      emit "orl $#{BOOL_TAG}, %eax" # Tag as boolean
    when '!'
      emit_expr x.invocant
      emit "xorl $1, %eax"
    end
  end

  # Given a parse tree, emit an AST.
  def make_ast p
    p.elements.select do |e|
      e.kind_of? ObjLang::Statement or e.kind_of? ObjLang::Expr
    end.map do |e|
      case e
      when ObjLang::Statement
        to_abstract e
      when ObjLang::Expr
        AST::Statement.new(to_abstract e.meat)
      end
    end
  end

  def to_abstract e
    case e
    when ObjLang::Statement
      AST::Statement.new(to_abstract e.expr.meat)
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
    else
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
    when AST::MethodCall; x.message =~ /^succ|pred|nil\?|zero\?|!$/
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
