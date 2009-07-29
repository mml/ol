module Runtime
  BOOL_TAG     = 0b011_1110
  BOOL_MASK    = 0b111_1111
  BOOL_SHIFT   = 7

  WORD_SIZE    = 4

  FIXNUM_TAG   = 0b00
  FIXNUM_MASK  = 0b11
  FIXNUM_SHIFT = 2

  NIL_REP      = 0b10_1111
end

if __FILE__ == $0
  Runtime.constants.each do |c|
    puts %Q{#define #{c} #{eval "Runtime::#{c}"}}
  end
end
