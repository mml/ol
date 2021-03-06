# Pass 5: GenerateX86Code
#
# This pass takes the program and emits x86 assembly suitable for handing to
# `as`.
#
# The input to this pass is the output from LiftProcedure.
class GenerateX86Code < CompilerPass
  include Runtime
  @@n = 0

  def rewrite_program p
    p.labels.each {|label,fn|
      emit_label label
      emit_proc fn.formals, fn.body, -4, {}
    }

    # Program body
    emit <<-EOT
      .text
      .align 4,0x90
      .globl _ol_entry
    EOT
    emit_label '_ol_entry' # XXX This should probably be a param.
    emit "movl %eax, %esi" # Copy heap pointer
    emit_expr p, -4, {}
    emit 'ret'
    emit '.subsections_via_symbols'
  end

  def one
    1 << FIXNUM_SHIFT
  end

  def zero
    0
  end

  def emit_expr x, si, env
    case
    when x.kind_of?(Integer)
      emit "movl $#{x}, %eax"
    when x.primcall?
      emit_primitive_call x, si, env
    when x.seq?
      x.exprs.each do |e|
        emit_expr e, si, env
      end
    when x.let?
      emit_expr x.rhs, si, env
      emit "movl %eax, #{si}(%esp)"
      nenv = env.merge x.lhs => si
      emit_expr x.body, si - WORD_SIZE, nenv
    when x.varref?
      emit "movl #{env[x.name]}(%esp), %eax"
    when x.if?
      emit_if x.test, x.cons, x.alt, si, env
    when x.prog?
      emit_expr x.expr, si, env
    when x.kind_of?(AST::LabelCall)
      nsi = si - WORD_SIZE
      x.args.each do |arg|
        emit_expr arg, nsi, env
        emit "movl %eax, #{nsi}(%esp)"
        nsi -= WORD_SIZE
      end
      emit "subl $#{-si - WORD_SIZE}, %esp"
      emit "call #{x.label}"
      emit "addl $#{-si - WORD_SIZE}, %esp"
    when x.kind_of?(AST::Alloc)
      x.init.each_with_index do |n,i|
        emit "movl $#{n}, #{i * WORD_SIZE}(%esi)"
      end
      emit "movl %esi, %eax"
      emit "orl $#{x.tag}, %eax"
      emit "addl $#{round_up x.byte_count}, %esi"    # bump ESI
    else
      raise "Cannot emit #{x} #{x.class}"
    end
  end

  def round_up n
    n - (n % ALIGNMENT) + ALIGNMENT
  end

  def emit_proc formals, body, si, env
    # This is a bit ugly.  -Matt
    formals.each do |formal|
      env[formal] = si
      si -= 4
    end
    emit_expr body, si, env
    emit 'ret'
  end

  def emit_primitive_call x, si, env
    case x.message
    when 'succ'
      emit_expr x.invocant, si, env
      emit "addl $#{one}, %eax"
    when 'pred'
      emit_expr x.invocant, si, env
      emit "subl $#{one}, %eax"
    when 'nil?'
      emit_expr x.invocant, si, env
      emit_compare "$#{NIL_REP}", 'e'
    when 'zero?'
      emit_expr x.invocant, si, env
      emit_compare "$#{zero}", 'e'
    when '!'
      emit_expr x.invocant, si, env
      emit "xorl $#{1 << BOOL_SHIFT}, %eax"
    when '+'
      emit_expr x.args[0], si, env
      emit "movl %eax, #{si}(%esp)"
      emit_expr x.invocant, si - WORD_SIZE, env
      emit "addl #{si}(%esp), %eax"
    when '-'
      emit_expr x.args[0], si, env
      emit "movl %eax, #{si}(%esp)"
      emit_expr x.invocant, si - WORD_SIZE, env
      emit "subl #{si}(%esp), %eax"
    when '*'
      emit_expr x.args[0], si, env
      emit "movl %eax, #{si}(%esp)"
      emit_expr x.invocant, si - WORD_SIZE, env
      emit "sarl $#{FIXNUM_SHIFT}, %eax"
      emit "imull #{si}(%esp), %eax"
    when '=='
      emit_expr x.args[0], si, env
      emit "movl %eax, #{si}(%esp)"
      emit_expr x.invocant, si - WORD_SIZE, env
      emit_compare "#{si}(%esp)", 'e'
    when '<'
      emit_expr x.args[0], si, env
      emit "movl %eax, #{si}(%esp)"
      emit_expr x.invocant, si - WORD_SIZE, env
      emit_compare "#{si}(%esp)", 'l'
    when '<='
      emit_expr x.args[0], si, env
      emit "movl %eax, #{si}(%esp)"
      emit_expr x.invocant, si - WORD_SIZE, env
      emit_compare "#{si}(%esp)", 'le'
    when '>'
      emit_expr x.args[0], si, env
      emit "movl %eax, #{si}(%esp)"
      emit_expr x.invocant, si - WORD_SIZE, env
      emit_compare "#{si}(%esp)", 'g'
    when '>='
      emit_expr x.args[0], si, env
      emit "movl %eax, #{si}(%esp)"
      emit_expr x.invocant, si - WORD_SIZE, env
      emit_compare "#{si}(%esp)", 'ge'
    when 'push'
      emit_expr x.args[0], si, env              # New value -> stack
      emit "movl %eax, #{si}(%esp)"

      emit_expr x.invocant, si - WORD_SIZE, env# Array pointer -> EAX
      emit "xorl $#{ARRAY_TAG}, %eax"

      emit "movl #{WORD_SIZE}(%eax), %edx"      # size into EDX

      # New value in to the next spot
      emit "movl #{si}(%esp), %ecx"
      emit "movl %ecx, #{WORD_SIZE * 2}(%eax,%edx,#{WORD_SIZE})"

      emit "incl %edx"                          # increment size (in EDX)
      emit "movl %edx, #{WORD_SIZE}(%eax)"      # write size back from EDX

      emit "orl $#{ARRAY_TAG}, %eax"            # Restore tagged pointer to EAX
    end
  end

  def emit_if test, cons, alt, si, env
    l0 = unique_label
    l1 = unique_label
    emit_expr test, si, env
    emit "cmpl $#{FALSE_REP}, %eax"
    emit "je #{l0}"
    emit_expr cons, si, env
    emit "jmp #{l1}"
    emit_label l0
    emit_expr alt, si, env
    emit_label l1
  end

  def unique_label
    @@n += 1
    "__L#{@@n}"
  end

  def emit_label l
    @compiler.out.puts "#{l}:"
  end

  def emit_compare rand, flags
    emit "cmpl #{rand}, %eax"
    emit "movl $0, %eax"
    emit "set#{flags} %al"
    emit "sall $#{BOOL_SHIFT}, %eax" # Shift left by 7 bits
    emit "orl $#{BOOL_TAG}, %eax" # Tag as boolean
  end

  def emit s
    @compiler.out.puts "\t#{s}"
  end
end
