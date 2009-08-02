#!/usr/bin/env ruby

require 'compiler'
require 'ruby-debug'
require 'getoptlong'

class TestDriver
  @@test_cases = [
    # fixnum literals
    ['42', '42'],
    ['0', '0'],
    ['-18', '-18'],
    # other literals
    ['false', 'false'],
    ['true', 'true'],
    ['nil', 'nil'],
    # succ and pred
    ['9.succ()', '10'],
    ['10.succ()', '11'],
    ['-2.succ()', '-1'],
    ['-1.succ()', '0'],
    ['-1.succ().succ()', '1'],
    ['0.succ().pred()', '0'],
    ['1.pred()', '0'],
    ['0.pred()', '-1'],
    ['9.pred()', '8'],
    # character literals
    ['?A', '65'],
    # nil?, !, zero?
    ['9.nil?()', 'false'],
    ['nil.nil?()', 'true'],
    ['!true', 'false'],
    ['!false', 'true'],
    ['0.zero?()', 'true'],
    ['1.zero?()', 'false'],
    ['-1.zero?()', 'false'],
    ['!1.zero?()', 'true'],
    ['-1.succ().zero?()', 'true'],
    ['1.pred().zero?()', 'true'],
    ['0.succ().zero?()', 'false'],
    ['!-1.succ().zero?()', 'false'],
    # binary primitives
    ['1 + 1', '2'],
    ['-5 + 6', '1'],
    ['1 - 2', '-1'],
    ['1 == 1', 'true'],
    ['0 == 1', 'false'],
    ['(?0 + 9) == ?9', 'true'],
    ['(?9 - 5) == ?4', 'true'],
    ['!((?9 - 5) == ?4)', 'false'],
    ['9 * 9', '81'],
    ['((?5 - ?0) * (?2 - ?0)) == (5*2)', 'true'],
    ['16384 * 16384', '268435456'],
    ['(16384 * 16384)*0', '0'],
    ['16384 * -16384', '-268435456'],
    ['-1 < 0', 'true'],
    ['0 < -1', 'false'],
    ['0 < 0', 'false'],
    ['1 < 1', 'false'],
    ['-1 > 0', 'false'],
    ['0 > -1', 'true'],
    ['0 > 0', 'false'],
    ['1 > 1', 'false'],
    ['0 <= 0', 'true'],
    ['0 <= 1', 'true'],
    ['1 <= 0', 'false'],
    ['0 >= 0', 'true'],
    ['0 >= 1', 'false'],
    ['1 >= 0', 'true'],
    ['nil==nil', 'true'],
    ['true==true', 'true'],
    ['true==nil', 'false'],
    ['false==nil', 'false'],
    ['false==0', 'false'],
    ['true==1', 'false'],
    ['false==false', 'true'],
    # Assignment
    ['x=1; x+1', '2'],
    ['foo=186; foo+1', '187'],
    ['x=5; y=10; x+y', '15'],
    ['x=5; y=x+1; z=x*y; z*2', '60'],
    ['t=true; f=false; t==f', 'false'],
    ['x=10; y = x + 100; 100 > y', 'false'],
    # Conditionals
    ['if 0 < 5; nil; else; 20; end', 'nil'],
    ['x=1; y=x+1; z=x+y; if x <= y; z; else; x; end', '3'],
    ['if false; 1; else; 0; end', '0'],
    [:skip, 'if nil; false; else; true; end', 'true'],
    # Procedures
    ['def f(); 31337; end; f()', '31337'],
    ['def f(x); x.succ(); end; f(50)', '51'],
    ['def fib(n); if n < 2; 1; else; fib(n-1)+fib(n-2); end; end; fib(10)', '89'],
    ['def f(x,y); if x == 0; y; else; f(x-1,y+1); end; end; f(10,20)', '30'],
    ['def f(x,y,z); if x == 0; g(y,z); else; f(x-1,y+1,z); end; end; def g(y,z); if y == 0; z; else; f(y,-1,z+1); end; end; f(20,30,50)', '100'],
    ['def mult(a,b)
        accum(a,b,0)
      end
      def accum(a,b,x)
        if a == 0
          x
        else
          accum(a-1,b,x+b)
        end
      end
      mult(633,23)', '14559'],
    ['def mult(a,b)
        accum(a,b,0)
      end
      def accum(a,b,x)
        if a == 0
          x
        else
          accum(a-1,b,x+b)
        end
      end
      a=2
      a=mult(a,a)
      a=mult(a,a)
      a=mult(a,a)
      a=mult(a,a)' , '65536'],
    ['def mult(a,b)
        accum(a,b,0)
      end
      def accum(a,b,x)
        if a == 0
          x
        else
          accum(a-1,b,x+b)
        end
      end
      a=mult(mult(mult(2,2),mult(2,2)),mult(mult(2,2),mult(2,2)))' , '256'],
      [:todo, 'def mult(a,b)
          accum(a,b,0)
        end
        def accum(a,b,x)
          if a == 0
            x
          else
            accum(a-1,b,x+b)
          end
        end
        mult(
          mult(
            mult(
              mult(2,2),
              mult(2,2)
            ),
            mult(
              mult(2,2),
              mult(2,2)
            )
          ),
          mult(
            mult(
              mult(2,2),
              mult(2,2)
            ),
            mult(
              mult(2,2),
              mult(2,2)
            )
          )
        )','65536'],
    ['def mult(a,b)
        accum(a,b,0)
      end
      def accum(a,b,x)
        if a == 0
          x
        else
          accum(a-1,b,x+b)
        end
      end
      def pow(a,b)
        accup(a,b,1)
      end
      def accup(a,b,x)
        if a == 0
          x
        else
          accup(a-1,b,mult(x,b))
        end
      end
      pow(10,2)', '1024'],
    ['Array.new()', '[]'],
    ['Array.new().push(42)', '[42]'],
    [:todo, 'Array.new().push(1).push(2)', '[1,2]'],
  ]

  attr_accessor :todo_only

  def initialize
    @as = 'test.s'
    @exe = 'test'
    @f = File.open @as, 'w'
    @c = Compiler.new @f
    todo_only = false
  end

  def run_tests
    failures = []

    system 'gcc -g -O3 --omit-frame-pointer -c driver.c'

    pass = 0
    skip = 0
    unexpected = 0
    todo = 0

    cases = todo_only ? @@test_cases.select {|c| :todo == c[0]} : @@test_cases
    for flag,source,expected in cases
      if flag.is_a? Symbol
        if flag == :skip
          skip += 1
          print 'S'
          next
        end
      else
        expected=source
        source=flag
      end

      begin
        @f.truncate 0
        @f.seek 0
        write_prologue
        @c.compile_program source
        write_epilogue
        @f.flush
        link_out = link #FIXME: Need to emit this with failure messages

        if (r = run) == expected
          if flag == :todo
            print '!'
            unexpected += 1
          else
            print '.'
            pass += 1
          end
        else
          if flag == :todo
            print 'T'
            todo += 1
          else
            print 'F'
            failures.push [r,source,expected,`cat test.s`]
          end
        end
      rescue => e
        if flag == :todo
          print 'T'
          todo += 1
        else
          print 'E'
          failures.push [e, source]
        end
      end
    end
    puts

    printf "%d/%d passed (%.0f%%)\n",
      pass, cases.count, 100 * pass / cases.count
    printf "%d to do tests unexpectedly passed!", unexpected if unexpected > 0
    printf "%d to do\n", todo if todo > 0
    printf "%d skipped\n", skip if skip > 0

    failures.each do |failure|
      case failure.length
      when 4
        puts "'#{failure[0]}' != '#{failure[2]}'"
        puts failure[3]
      when 2
        puts failure[0]
        puts failure[0].backtrace
      end
      puts "  #{failure[1]}"
    end
  end

  def write_prologue
    @f.print <<EOT
	.text
	.align 4,0x90
.globl _ol_entry
EOT
  end

  def write_epilogue
    @f.print <<EOT
	.subsections_via_symbols
EOT
  end

  def link
    `gcc -g -o #{@exe} #{@as} driver.o 2>&1`.chomp
  end

  def run
    `./#{@exe} 2>&1`.chomp
  end
end

if __FILE__ == $0
  opts = GetoptLong.new(
    [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
    [ '--todo', '-t', GetoptLong::NO_ARGUMENT ]
  )

  driver = TestDriver.new

  opts.each do |opt, arg|
    case opt
    when '--help'
      puts <<-"EOT"
        Usage: #{$0} [OPTION]

          -h, --help                   Show this message.
          -t, --todo                   Run only TODO tests.
      EOT
      exit 1
    when '--todo'
      driver.todo_only = true
    end
  end

  driver.run_tests
end
