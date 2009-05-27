#!/usr/bin/env ruby
require 'yaml'
require 'rubygems'
require 'treetop'
Treetop.load 'ol'

parser = ObjLangParser.new
programs = YAML::load_file 'programs.yml'
    
programs.map(){|p| p.to_s}.each() {|p|
  if parser.parse(p)
    print '.'
  else
    puts "failure: #{p}\n#{parser.failure_reason}"
  end
}
puts
