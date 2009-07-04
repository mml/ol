require 'compiler'

class TestDriver
  @@test_cases = [['42', '42'], ['0', '0'], ['-18', '-18']]

  def initialize
    @as = 'test.s'
    @exe = 'test'
    @f = File.open @as, 'w'
    @c = Compiler.new @f
  end

  def run_tests
    for source,expected in @@test_cases
      @f.truncate 0
      @f.seek 0
      write_prologue
      @c.compile_program source.to_i
      write_epilogue
      @f.flush
      link

      if run == expected
        print '.'
      else
        raise "FAIL"
      end
    end
    puts
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
