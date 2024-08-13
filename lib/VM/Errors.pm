#!perl

use v5.40;
use experimental qw[ class builtin ];
use builtin      qw[ export_lexically ];

use Carp ();

use VM::Internal::Tools;

class VM::Errors {
    class VM::Errors::Error :isa(VM::Internal::Tools::Enum) {}

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
            my $e    = $ERRORS[$i];
            my $enum = VM::Errors::Error->new( int => $i++, label => $e );
            constant->import( $e => $enum );
        }
    }

    sub import {
        export_lexically(
            '&throw' => \&throw
        );
    }

    sub throw ($e) { Carp::confess("$e") }
}
