#!perl

use v5.40;
use experimental qw[ class ];

use VM::Core;
use VM::Memory;

use VM::Assembler;

class VM {
    use constant DEBUG => $ENV{DEBUG} // 0;

    field $heap_size :param :reader = 100;

    field $assembler :reader;
    field $core      :reader;
    field $memory    :reader;

    field @out_buffer;

    ADJUST {
        $assembler = VM::Assembler->new;
        $memory    = VM::Memory->new;
        $core      = VM::Core->new(
            heap       => $memory->allocate_block( $heap_size ),
            out_buffer => \@out_buffer
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

    method execute ($debugger=undef) {
        try {
            $core->execute( DEBUG ? $debugger : () );
        } catch ($e) {
            warn $e;
        }

        if (@out_buffer) {
            say @out_buffer;
        }
    }
}
