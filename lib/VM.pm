#!perl

use v5.40;
use experimental qw[ class ];

use VM::CPU;
use VM::Memory;
use VM::Clock;
use VM::Channel;
use VM::Interrupts;

use VM::Assembler;
use VM::Debugger;

class VM {
    use constant DEBUG => $ENV{DEBUG} // 0;

    field $heap_size :param :reader = 100;

    field $assembler :reader;

    # CPU and RAM
    field $clock  :reader;
    field $cpu    :reader;
    field $memory :reader;
    # serial input/ouput device
    field $sod    :reader;
    field $sid    :reader;

    ADJUST {
        $sod    = VM::Channel->new;
        $sid    = VM::Channel->new;
        $memory = VM::Memory->new;
        $clock  = VM::Clock->new;
        $cpu    = VM::CPU->new(
            heap => $memory->allocate_block( $heap_size ),
            sod  => $sod,
            sid  => $sid,
        );

        # create an assembler for later ...
        $assembler = VM::Assembler->new;

        # attache the debugger to the Interrupt handler ...
        $VM::Interrupts::DEBUGGER = VM::Debugger->new( vm => $self ) if DEBUG;
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
        try {
            until ($cpu->halted) {
                # set the debugger to run if we are debugging
                $cpu->irq = VM::Interrupts->DEBUG if DEBUG;
                $clock->tick( $cpu )
            }
        } catch ($e) {
            chomp $e;
            die "Unexpected Runtime Exception: $e";
        }
    }
}
