require 'rubygems'
require 'treetop'
Treetop.load 'ol'

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

  module Program
  end

  module Statement
  end
  
  module Expr
  end

  module AtomicExpr; end
  module TrueLiteral; end
  module FalseLiteral; end
  module NilLiteral; end

  module MessageChain
    def deparse
      elements.map {|node|
        '.' + node.message.deparse
      }
    end
  end

  module EndExpr
    def deparse
      "\n"
    end
  end

  module Integer
    def deparse
      text_value
    end
  end

  module Identifier
    def deparse
      text_value
    end
  end

  module Whitespace
  end

  module ClassDef
    def deparse
      "class #{name.deparse}\n#{body.deparse}end\n"
    end
  end

  module MethDef
    def deparse
      "def #{name.deparse}(#{formal_ids.map(&:deparse).join(',')})\n#{body.deparse}end\n"
    end

    def formal_ids
      if formals.empty?
        []
      else
        [formals.first] + formals.rest.elements.map(&:id)
      end
    end
  end

  module Message
    def deparse
      "#{method.deparse}(#{param_exprs.map(&:deparse).join(',')})"
    end

    def param_exprs
      if params.empty?
        []
      else
        [params.first] + params.rest.elements.map(&:expr)
      end
    end
  end
  
  module Assignment
    def deparse
      "#{lhs.deparse} = #{rhs.deparse}\n"
    end
  end

  module IfExpr
    def deparse
      "if #{test.deparse}\n#{cons.deparse}\n#{if_rest.deparse}"
    end
  end

  module ElseExpr
    def deparse
      "else\n#{alt.deparse}\nend\n"
    end
  end

  module OpApp
    def deparse
      "#{rand1.deparse} #{op.text_value} #{rand2.deparse}"
    end
  end

  module Parens
    def deparse
      "(#{expr.deparse})"
    end
  end
end

class Treetop::Runtime::SyntaxNode
  include ObjLang::Deparse

  attr_writer :elements
end

