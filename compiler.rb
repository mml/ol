class Compiler
  def initialize( o = STDOUT )
    @out = o
  end

  def compile_program x
    emit "movl $#{x}, %eax"
    emit "ret"
  end

  def emit s
    @out.puts "\t#{s}"
  end
end
