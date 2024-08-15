#!perl

use v5.40;
use experimental qw[ class builtin ];

use Scalar::Util ();
use Sub::Util    ();

use VM;
use VM::Assembler::Assembly;
use VM::Debugger;

my $vm = VM->new;

$vm->assemble(
    label('.adder'),
        LOAD_ARG, 0,
        LOAD_ARG, 1,
        ADD_INT,
        RETURN,
    label('.doubler'),
        LOAD_ARG, 0,
        DUP,
        ADD_INT,
        RETURN,
    label('.main'),
        CONST_INT, i(10), # @a
        ALLOC_MEM, 1,

        CONST_INT, i(0), # $x
        CONST_INT, i(0), # $y

    label('.main.loop'),
        LOAD, 1, # $x
        LOAD, 2, # $y
        CALL, label('#adder'), 2,
        CALL, label('#doubler'), 1,

        DUP,
        LOAD, 1, # $x
        LOAD, 0, # @a
        STORE_MEM,

        LOAD, 1,
        CONST_INT, i(1),
        ADD_INT,
        STORE, 1,

        LOAD, 2,
        CONST_INT, i(1),
        ADD_INT,
        STORE, 2,

        CONST_INT, i(20),
        LT_INT,
        JUMP_IF_TRUE, label('#main.loop'),

    label('.main.exit'),
        LOAD, 0,
        FREE_MEM,
        HALT
);

$vm->execute;








