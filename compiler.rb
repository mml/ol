class Compiler
  @@BOOL_TAG = 0b0011_1110
  @@NIL      = 0b0010_1111

  def initialize( o = STDOUT )
    @out = o
  end

  def compile_program x
    emit "movl $#{immediate_rep x}, %eax"
    emit "ret"
  end

  def immediate_rep x
    case x
    when Fixnum
      x << 2
    when TrueClass
      @@BOOL_TAG | 0b1
    when FalseClass
      @@BOOL_TAG | 0b0
    when NilClass
      @@NIL
    end
  end

  def emit s
    @out.puts "\t#{s}"
  end
end
