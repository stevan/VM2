#!perl

use v5.40;
use experimental qw[ class builtin ];

use VM;
use VM::Assembler::Assembly;
use VM::Debugger;

my $vm = VM->new;

=pod

    get a character and print it ...

=cut

$vm->assemble(
    label('.main'),
        BREAKPOINT,
        CONST_CHAR, c('?'), PUT,
        CONST_CHAR, c(' '), PUT,

    label('.main.getc'),
        GET_CHAR,
        DUP,
        IS_NULL,
        JUMP_IF_FALSE, label('#main.print'),
        HALT,
        JUMP, label('#main.getc'),

    label('.main.print'),
        CONST_CHAR, c("\n"), PUT,
        CONST_CHAR, c('>'), PUT,
        CONST_CHAR, c(' '), PUT,
        PUT,

        CONST_CHAR, c("\n"), PUT,
        EXIT,
);

$vm->execute;





