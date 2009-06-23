#!/usr/bin/env ruby
require 'yaml'
require 'rubygems'
require 'treetop'

Treetop.load 'ol'
require 'lang'
require 'p1'
require 'YAML'

def main
  parser = ObjLangParser.new
  programs = YAML::load_file 'programs.yml'

  puts 'parse'
  programs.each {|p|
    if !skip? p
      if parser.parse(p)
        print '.'
      else
        puts "failure: #{p}\n#{parser.failure_reason}"
      end
    end
  }

  puts "\n\ndeparse"
  i = 0
  programs.each {|p|
    i += 1
    if !skip? p
      if ast = parser.parse(p)
        begin
          #ast = Compiler::RegularizeTree.run(ast)
          #ast = Compiler::FlattenTree.run(ast)
          a = run p
          b = run ast.deparse
        rescue NoMethodError
          puts "\n" + YAML::dump([$!.message, ast.pretty_inspect, p, $!.backtrace.join("\n")])
          return
        end

        if a == b
          print '.'
        else
          puts("\nfail #{i}\n" + { :programs => [p, ast.deparse], :outputs => [a, b]}.to_yaml)
          exit
        end
      else
        print 'P'
      end
    end
  }

  puts ''
end

def skip? p
  return false unless p.is_a? Hash

  if p['TODO']
    print 'T'
  else
    print 'S'
  end
  true
end

def run p
  out_r, out_w = IO.pipe
  in_r, in_w = IO.pipe

  fork {
    in_w.close
    out_r.close
    $stderr.reopen out_w
    $stdout.reopen out_w
    $stdin.reopen in_r
    exec 'ruby'
  }
  out_w.close
  in_r.close
  in_w.print p
  in_w.close
  result = out_r.read
  out_r.close

  result
end

main
