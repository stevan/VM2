#!perl

use v5.40;
use experimental qw[ class ];

use VM::Core;
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
    field $core      :reader;
    field $memory    :reader;
    # serial input/ouput devices
    field $sod :reader;
    field $sid :reader;

    ADJUST {
        $sod = VM::Channel->new;
        $sid = VM::Channel->new;

        $debugger  = VM::Debugger->new( vm => $self ) if DEBUG;
        $assembler = VM::Assembler->new;
        $memory    = VM::Memory->new;
        $core      = VM::Core->new(
            heap => $memory->allocate_block( $heap_size ),
            sod  => $sod,
            sid  => $sid,
            (DEBUG ? (debugger => $debugger) : ()),
        );
    }

    method heap { $core->heap }

    method assemble (@source) {
        $assembler->assemble(\@source);

        $core->load_code(
            $assembler->label_to_addr->{'main'},
            $assembler->code
        );
    }

    method execute {
        $core->irq = VM::Interrupts->DEBUG if DEBUG;
        try {
            $core->execute;
        } catch ($e) {
            chomp $e;
            die "Unexpected Runtime Exception: $e";
        }
    }
}
