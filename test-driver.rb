require 'compiler'
require 'ruby-debug'

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
    #['if nil; false; else; true; end', 'true'],
  ]

  def initialize
    @as = 'test.s'
    @exe = 'test'
    @f = File.open @as, 'w'
    @c = Compiler.new @f
  end

  def run_tests
    failures = []

    system 'gcc -O3 --omit-frame-pointer -c driver.c'

    pass = 0

    for source,expected in @@test_cases
      begin
        @f.truncate 0
        @f.seek 0
        write_prologue
        @c.compile_program source
        write_epilogue
        @f.flush
        link

        if (r = run) == expected
          print '.'
          pass += 1
        else
          print 'F'
          failures.push [r,source,expected]
        end
      rescue => e
        print 'E'
        failures.push [e.to_s, source]
      end
    end
    puts

    printf "%d/%d passed (%.0f%%)\n",
      pass, @@test_cases.count, 100 * pass / @@test_cases.count

    failures.each do |failure|
      case failure.length
      when 3
        puts "'#{failure[0]}' != '#{failure[2]}'"
      when 2
        puts failure[0]
      end
      puts "  #{failure[1]}"
    end
  end

  def write_prologue
    @f.print <<EOT
	.text
	.align 4,0x90
.globl _ol_entry
_ol_entry:
EOT
  end

  def write_epilogue
    @f.print <<EOT
	.subsections_via_symbols
EOT
  end

  def link
    system "gcc -o #{@exe} #{@as} driver.o"
  end

  def run
    `./#{@exe}`.chomp
  end
end
