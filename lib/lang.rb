require 'rubygems'
require 'treetop'
Treetop.load 'ol'

class Treetop::Runtime::SyntaxNode
  attr_writer :elements
end

module ObjLang
  module Program
    def exprs
      stmts.elements.map(&:expr) +
        if expr.empty?
          []
        else
          [expr]
        end
    end
  end

  module MethDef
    def formal_ids
      if formals.empty?
        []
      else
        [formals.first] + formals.rest.elements.map(&:id)
      end
    end
  end

  module Message
    def param_exprs
      if params.empty?
        []
      else
        [params.first] + params.rest.elements.map(&:expr)
      end
    end
  end

  module Array
    def member_exprs
      if members.empty?
        []
      else
        [members.first] + members.rest.elements.map(&:expr)
      end
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
