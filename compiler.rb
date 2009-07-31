for dir in %w( lib passes ) do
  Dir.glob("#{File.dirname(__FILE__)}/#{dir}/*.rb").each{|file| require file}
end

class Compiler
  include Runtime
  attr_accessor :out

  PASSES = [
    ParseConcreteSyntax,
    BuildAST,
    IdentifyAlloc,
    LiftProcedure,
    GenerateX86Code
  ]

  def initialize( o = STDOUT )
    self.out = o
  end

  def compile_program string
    p = string

    for pass in PASSES
      p = pass.new(self).rewrite_program(p)
    end
  end

  def assert condition
    raise "Failed assertion." unless condition
  end
end
