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
    def alloc_array?; false; end
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
      message =~ /^succ|pred|nil\?|zero\?|!|\+|-|==|<|>|<=|>=|\*|push$/
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
  class AllocArray
    include Node
    def alloc_array?; true; end
  end
end
