#!perl

use v5.40;
use experimental qw[ class ];

use VM::Core;

class VM {
    field $core;

    ADJUST {
        $core = VM::Core->new;
    }

    method load_code ($code) { $core->load_code( $code ) }
    method execute           { $core->execute }
}
