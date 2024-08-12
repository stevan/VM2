#!perl

use v5.40;
use experimental qw[ class builtin ];

use VM::Internal::Tools;

class VM::Errors {
    our @ERRORS;
    BEGIN {
        @ERRORS = qw[
            INVALID_POINTER

            POINTER_UNDERFLOW
            POINTER_OVERFLOW

            POINTER_ALREADY_FREED

            MEMORY_UNDERFLOW
            MEMORY_OVERFLOW

            OUT_OF_MEMORY
        ];
        foreach my $i ( 0 .. $#ERRORS ) {
            no strict 'refs';
            my $op   = $ERRORS[$i];
            my $enum = enum $i++, $op;
            constant->import( $op => $enum );
        }
    }
}
