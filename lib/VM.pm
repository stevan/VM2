#!perl

use v5.40;
use experimental qw[ class ];

use VM::Core;
use VM::Memory;

use VM::Assembler;

class VM {
    field $heap_size :param :reader = 100;

    field $core;
    field $memory;

    ADJUST {
        $memory = VM::Memory->new;
        $core   = VM::Core->new(
            heap => $memory->allocate_block( $heap_size )
        );
    }

    method assemble (@source) {
        my $assembler = VM::Assembler->new;

        my $code = $assembler->assemble(@source);

        $core->load_code( $code )
    }

    method execute { $core->execute }
}
