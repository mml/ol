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
  ]

  def initialize
    @as = 'test.s'
    @exe = 'test'
    @f = File.open @as, 'w'
    @c = Compiler.new @f
  end

  def run_tests
    failures = []

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
        else
          print 'F'
          failures.push [r,source,expected]
        end
      rescue
        print 'P'
      end
    end
    puts

    failures.each do |failure|
      puts "'#{failure[0]}' != '#{failure[2]}'"
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
    system "gcc -O3 --omit-frame-pointer -o #{@exe} #{@as} driver.c"
  end

  def run
    `./#{@exe}`.chomp
  end
end
