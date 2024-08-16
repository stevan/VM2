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
        #BREAKPOINT,
        CONST_INT, i(20),
        ALLOC_MEM, 1,

        CONST_INT, i(0), # count up
        CONST_INT, i(0), # count down

        CONST_CHAR, c('?'), PUT,
        CONST_CHAR, c(' '), PUT,

    label('.main.getc'),
        HALT,

        GET_CHAR,
        DUP,
        CONST_CHAR, c("\n"),
        EQ_CHAR,
        JUMP_IF_TRUE, label('#main.print'),

        #BREAKPOINT,

        DUP,
        PUT,

        LOAD, 1,
        LOAD, 0,
        STORE_MEM,

        #BREAKPOINT,

        LOAD, 1,
        INC_INT,
        STORE, 1,

        JUMP, label('#main.getc'),

    label('.main.print'),
        PUT,
        CONST_CHAR, c('>'), PUT,
        CONST_CHAR, c(' '), PUT,

    label('.main.print.loop'),
        #BREAKPOINT,
        LOAD, 2,
        LOAD, 0,
        LOAD_MEM,
        PUT,

        LOAD, 2,
        INC_INT,
        DUP,
        STORE, 2,

        LOAD, 1,
        EQ_INT,
        JUMP_IF_FALSE, label('#main.print.loop'),

        CONST_CHAR, c("\n"), PUT,
        EXIT,
);

$vm->execute;





