require 'compiler'
require 'ruby-debug'

class TestDriver
  @@test_cases = [
    ['42', '42'],
    ['0', '0'],
    ['-18', '-18'],
    ['false', 'false'],
    ['true', 'true'],
    ['nil', 'nil'],
    ['9.succ()', '10'],
    ['10.succ()', '11'],
    ['-2.succ()', '-1'],
    ['-1.succ()', '0'],
    ['-1.succ().succ()', '1'],
    ['0.succ().pred()', '0'],
    ['1.pred()', '0'],
    ['0.pred()', '-1'],
    ['9.pred()', '8'],
    ['?A', '65'],
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
