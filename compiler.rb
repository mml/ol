require 'lang'

module AST
  Statement    = Struct.new :expr
  TrueLiteral  = :true
  FalseLiteral = :false
  NilLiteral   = :nil
  Integer      = Struct.new :value
end

class Compiler
  @@BOOL_TAG = 0b0011_1110
  @@NIL      = 0b0010_1111

  def initialize( o = STDOUT )
    @out = o
    @parser = ObjLangParser.new
  end

  def compile_program string
    stmts = make_ast(@parser.parse(string))
    return_immediate stmts[0].expr
  end

  def return_immediate x
    emit "movl $#{immediate_rep x}, %eax"
    emit "ret"
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
    when ObjLang::AtomicExpr
      assert e.chain.empty?
      to_abstract e.base
    when ObjLang::TrueLiteral
      AST::TrueLiteral
    when ObjLang::FalseLiteral
      AST::FalseLiteral
    when ObjLang::NilLiteral
      AST::NilLiteral
    when ObjLang::Integer
      AST::Integer.new e.text_value.to_i
    else
      raise "Can't translate #{e}\n"
    end
  end

  def immediate_rep x
    case x
    when AST::Integer
      x.value << 2
    when AST::TrueLiteral
      @@BOOL_TAG | 0b1
    when AST::FalseLiteral
      @@BOOL_TAG | 0b0
    when AST::NilLiteral
      @@NIL
    end
  end

  def emit s
    @out.puts "\t#{s}"
  end

  def assert condition
    raise "Failed assertion." unless condition
  end
end
