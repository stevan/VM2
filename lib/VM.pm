#!perl

use v5.40;
use experimental qw[ class ];

use VM::CPU;
use VM::Memory;
use VM::Clock;
use VM::Channel;
use VM::Interrupts;

use VM::Assembler;

class VM {
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

        $assembler = VM::Assembler->new;
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
            $clock->tick( $cpu ) until $cpu->halted;
        } catch ($e) {
            chomp $e;
            die "Unexpected Runtime Exception: $e";
        }
    }
}
