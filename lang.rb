require 'ruby-debug'

module ObjLang
  module Deparse
    def deparse
      if elements
        elements.map(&:deparse).join
      else
        ''
      end
    end
  end

  class Node < Treetop::Runtime::SyntaxNode
  end

  class Program < Node
  end

  class EndExpr < Node
    def deparse
      "\n"
    end
  end

  class Integer < Node
    def deparse
      text_value
    end
  end

  class Identifier < Node
    def deparse
      text_value
    end
  end

  class Whitespace < Node
  end

  class ClassDef < Node
    def deparse
      "class #{name.deparse}\n#{class_body.deparse}end\n"
    end
  end

  class MethDef < Node
    def deparse
      "def #{name.deparse}()\n#{meth_body.deparse}end\n"
    end

    def name; id; end
  end
  
  class Assignment < Node
    def deparse
      "#{lhs.deparse} = #{rhs.deparse}\n"
    end

    def lhs; varref; end
    def rhs; expr; end
  end

  class IfExpr < Node
    def deparse
      "if #{test.deparse}\n#{cons.deparse}\n#{rest.deparse}"
    end

    def test; expr; end
    def cons; stmts; end
    def rest; if_rest; end
  end

  class ElseExpr < Node
    def deparse
      "else\n#{alt.deparse}\nend\n"
    end

    def alt; stmts; end
  end

  class OpApp < Node
    def deparse
      "#{rand1.deparse} #{rator.text_value} #{rand2.deparse}"
    end

    def rator; op; end
    def rand1; atomic_expr; end
    def rand2; simple_expr; end
  end

  class Parens < Node
    def deparse
      "(#{expr.deparse})"
    end

    def expr; simple_expr; end
  end
end

class Treetop::Runtime::SyntaxNode
  include ObjLang::Deparse

  attr_writer :elements
end

