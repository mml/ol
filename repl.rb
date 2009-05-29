require 'yaml'
require 'rubygems'
require 'treetop'
Treetop.load 'ol'
require 'lang'

$p = ObjLangParser.new
$prog = YAML::load_file 'programs.yml'

def p prog
  $p.parse prog
end

def pr n
  p $prog[n]
end
