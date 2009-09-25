require 'rubygems'
require 'treetop'
Treetop.load 'ol'

class Treetop::Runtime::SyntaxNode
  attr_writer :elements
end

module ObjLang
  module Helpers
    def first_plus_rest(l, extract)
      if l.empty?
        []
      else
        [l.first] + l.rest.elements.map(&extract)
      end
    end
  end

  module Program
    def exprs
      stmts.elements.map(&:expr) + (expr.empty? ? [] : [expr])
    end
  end

  module MethDef
    include Helpers

    def formal_ids
      first_plus_rest formals, :id
    end
  end

  module Message
    include Helpers

    def param_exprs
      first_plus_rest params, :expr
    end
  end

  module Array
    include Helpers

    def member_exprs
      first_plus_rest members, :expr
    end
  end

  module Statement; end
  module Expr; end
  module AtomicExpr; end
  module TrueLiteral; end
  module FalseLiteral; end
  module NilLiteral; end
  module Character; end
  module VarRef; end
  module MessageChain; end
  module EndExpr; end
  module Integer; end
  module Identifier; end
  module Whitespace; end
  module ClassDef; end
  module Assignment; end
  module IfExpr; end
  module ElseExpr; end
  module OpApp; end
  module UnaryOp; end
  module Parens; end
end
