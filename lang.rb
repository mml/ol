module ObjLang
  module Deparse
    def deparse
      if elements
        elements.map{|e| e.deparse}.join
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
      "class #{const_id.deparse}\n#{class_body.deparse}end\n"
    end
  end
end

class Treetop::Runtime::SyntaxNode
  include ObjLang::Deparse
end

