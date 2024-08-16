#!perl

use v5.40;
use experimental qw[ class ];

use VM::Errors;
use VM::Interrupts;

class VM::CPU {
    # RAM
    field $heap :param :reader;
    # serial input/ouput devices
    field $sod  :param :reader;
    field $sid  :param :reader;

    field @code  :reader;
    field @stack :reader;

    field $ic :reader =  0; # instruction counter (number of instructions run)
    field $pc :reader =  0; # program counter (points to current instruction)
    field $ci :reader =  0; # current instruction being run

    field $fp :reader =  0; # frame pointer (points to the top of the current stack frame)
    field $sp :reader = -1; # stack pointer (points to the current head of the stack)

    field $completed :reader = false;
    field $halted    :reader = false;

    field $irq = undef; # interrupt request register, used to signal an interrupt with VM::Interrupts type

    field @microcode;
    field @isr_table;

    method load_microcode       ($microcode) { @microcode = @$microcode }
    method load_interrupt_table ($isr_table) { @isr_table = @$isr_table }

    method load_code ($entry, $code) {
        @code      = @$code;
        @stack     = ();
        $ic        =  0;
        $pc        =  $entry;
        $ci        =  0;
        $fp        =  0;
        $sp        = -1;
        $irq       = undef;
        $completed = false;
        $halted    = false;
        $self;
    }

    method irq :lvalue { $irq }

    method push ($v) { $stack[++$sp] = $v }
    method pop       { $stack[$sp--]      }
    method peek      { $stack[$sp]        }

    method stack_index :lvalue ($idx) { $stack[$idx] }
    method code_index          ($idx) { $code[$idx]  }

    method next_op { $code[$pc++] }

    method jump_to ($addr) { $pc = $addr }
    method move_fp ($addr) { $fp = $addr }
    method move_sp ($addr) { $sp = $addr }

    method halt   { $halted = true  }
    method resume { $halted = false }
    method exit {
        $completed = true;
    }

    method execute {
        die VM::Errors->CODE_IS_ALREADY_COMPLETED
            if $completed;

        die "WTF" if $halted;

        if (!$halted && $pc < scalar @code) {
            $ci = $pc;
            my $opcode = $self->next_op;
            $microcode[$opcode]->($self);
            $ic++;

            if (defined $irq) {
                my $isr = $isr_table[$irq];
                $irq = undef;
                $isr->($self);
            }
        }

        $completed = true if $pc == scalar @code;

        return;
    }
}
