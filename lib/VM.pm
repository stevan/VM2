#!perl

use v5.40;
use experimental qw[ class ];

use VM::CPU;
use VM::Memory;
use VM::Channel;
use VM::Interrupts;

use VM::Assembler;

class VM {
    use constant DEBUG => $ENV{DEBUG} // 0;

    field $heap_size :param :reader = 100;

    field $assembler :reader;
    field $debugger  :reader;

    # CPU and RAM
    field $cpu   :reader;
    field $memory :reader;
    # serial input/ouput device
    field $sod    :reader;
    field $sid    :reader;

    ADJUST {
        $sod = VM::Channel->new;
        $sid = VM::Channel->new;

        $debugger  = VM::Debugger->new( vm => $self ) if DEBUG;
        $assembler = VM::Assembler->new;
        $memory    = VM::Memory->new;
        $cpu      = VM::CPU->new(
            heap => $memory->allocate_block( $heap_size ),
            sod  => $sod,
            sid  => $sid,
            (DEBUG ? (debugger => $debugger) : ()),
        );
    }

    method heap { $cpu->heap }

    method assemble (@source) {
        $assembler->assemble(\@source);

        $cpu->load_code(
            $assembler->label_to_addr->{'main'},
            $assembler->code
        );
    }

    method execute {
        $cpu->irq = VM::Interrupts->DEBUG if DEBUG;
        try {
            $cpu->execute;
        } catch ($e) {
            chomp $e;
            die "Unexpected Runtime Exception: $e";
        }
    }
}
