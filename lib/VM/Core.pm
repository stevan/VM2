#!perl

use v5.40;
use experimental qw[ class ];

use VM::Opcodes;

class VM::Core {
    field $heap       :param :reader;
    field $out_buffer :param :reader;

    field @code  :reader;
    field @stack :reader;

    field $ic :reader =  0; # instruction counter (number of instructions run)
    field $pc :reader =  0; # program counter (points to current instruction)
    field $ci :reader =  0; # current instruction being run

    field $fp :reader =  0; # frame pointer (points to the top of the current stack frame)
    field $sp :reader = -1; # stack pointer (points to the current head of the stack)

    field $running :reader = false;
    field $error = undef;

    field @microcode;

    ADJUST {
        @microcode = @VM::Opcodes::MICROCODE;
    }

    method load_code ($entry, $code) {
        @code  = @$code;
        @stack = ();
        $ic    =  0;
        $pc    =  $entry;
        $ci    =  0;
        $fp    =  0;
        $sp    = -1;
        $error = undef;
        $self;
    }

    method error :lvalue { $error }

    method to_out_buffer ($v) { unshift @$out_buffer => $v; }

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
        $sp      = -1;
        $fp      = 0;
    }

    method execute ($debugger=undef) {
        $error   = undef;
        $running = true;

        while ($running && $pc < scalar @code) {
            $ci = $pc;
            my $opcode = $self->next_op;
            $microcode[$opcode]->($self);
            $ic++;

            if ($debugger) {
                print "\e[2J\e[H\n";
                say join "\n" => $debugger->draw;
                if (my $sleep = $ENV{CLOCK}) {
                    Time::HiRes::sleep($sleep);
                } else {
                    my $x = <>;
                }
            }
        }
    }
}
