#!/usr/bin/env ruby

require 'compiler'
require 'ruby-debug'
require 'getoptlong'

class TestCase < Struct.new :flag, :source, :expected
  def initialize list
    self.flag, self.source, self.expected = list
    unless flag.is_a? Symbol
      self.expected, self.source, self.flag = source, flag, nil
    end
  end
end

class TestDriver
  @@test_cases = YAML::load_file('tests.yml')

  attr_accessor :failures, :passed, :skip, :unexpected, :todo, :todo_only, :test_case

  def self.dump_tests
    print YAML::dump(@@test_cases)
  end

  def initialize
    @as = 'test.s'
    @exe = 'test'
    @f = File.open @as, 'w'
    @c = Compiler.new @f
    self.todo_only = false
  end

  def run_tests
    self.failures = []

    system 'gcc -g -O3 --omit-frame-pointer -c driver.c'

    self.passed = 0
    self.skip = 0
    self.unexpected = 0
    self.todo = 0

    cases = todo_only ? @@test_cases.select {|c| :todo == c[0]} : @@test_cases
    for c in cases
      self.test_case = TestCase.new c

      if :skip == test_case.flag
        self.skip += 1
        print 'S'
        next
      end

      begin
        @f.truncate 0
        @f.seek 0
        @c.compile_program test_case.source
        @f.flush
        link_out = link #FIXME: Need to emit this with failure messages

        if (r = run) == test_case.expected
          pass
        else
          fail 'F', [r, test_case.source, test_case.expected, `cat test.s`]
        end
      rescue => e
        fail 'E', [e, test_case.source]
      end
    end
    puts

    printf "%d/%d passed (%.0f%%)\n",
      self.passed, cases.count, 100 * self.passed / cases.count
    printf "%d to do tests unexpectedly passed!\n", unexpected if unexpected > 0
    printf "%d to do\n", self.todo if self.todo > 0
    printf "%d skipped\n", self.skip if self.skip > 0

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

  def link
    `gcc -g -o #{@exe} #{@as} driver.o 2>&1`.chomp
  end

  def run
    `./#{@exe} 2>&1`.chomp
  end

  def fail mark, notes
    if :todo == test_case.flag
      print 'T'
      self.todo += 1
    else
      print mark
    end
    if todo_only or test_case.flag != :todo
      self.failures.push notes
    end
  end

  def pass
    if :todo == test_case.flag
      print '!'
      self.unexpected += 1
    else
      print '.'
    end
    self.passed += 1
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
