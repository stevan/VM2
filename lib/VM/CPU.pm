#!perl

use v5.40;
use experimental qw[ class ];

use importer 'Time::HiRes' => qw[ sleep ];

use VM::Opcodes;
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

    field $running :reader = false;
    field $halted  :reader = false;

    field $irq   = undef; # interrupt request register, used to signal an interrupt with VM::Interrupts type
    field $error = undef;

    field @microcode;
    field @isr_table;

    # optionally attach a debugger ...
    field $debugger :param :reader = undef;

    ADJUST {
        @microcode = @VM::Opcodes::MICROCODE;
        @isr_table = @VM::Interrupts::ISRS;
    }

    method load_code ($entry, $code) {
        @code    = @$code;
        @stack   = ();
        $ic      =  0;
        $pc      =  $entry;
        $ci      =  0;
        $fp      =  0;
        $sp      = -1;
        $irq     = undef;
        $error   = undef;
        $halted  = false;
        $running = false;
        $self;
    }

    method irq   :lvalue { $irq   }
    method error :lvalue { $error }

    method push ($v) { $stack[++$sp] = $v }
    method pop       { $stack[$sp--]      }
    method peek      { $stack[$sp]        }

    method stack_index :lvalue ($idx) { $stack[$idx] }

    method next_op { $code[$pc++] }

    method jump_to ($addr) { $pc = $addr }
    method move_fp ($addr) { $fp = $addr }
    method move_sp ($addr) { $sp = $addr }

    method halt {
        $running = false;
        $halted  = true;
    }

    method execute {
        $error   = undef;
        $running = true;

        while ($running && $pc < scalar @code) {
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
    }
}
