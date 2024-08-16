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
    label('.traverse'),
        CONST_INT, i(0),
        LOAD_ARG, 0,
        LOAD_MEM,
        PUT,
        CONST_INT, i(1),
        LOAD_ARG, 0,
        LOAD_MEM,
        DUP,
        IS_NULL,
        JUMP_IF_TRUE, label('#traverse.exit'),
        CALL, label('#traverse'), 1,
    label('.traverse.exit'),
        RETURN,

    label('.create_node'),
        CONST_INT, i(2),
        ALLOC_MEM, 1,

        LOAD_ARG, 0,
        CONST_INT, i(0),
        LOAD, 1,
        STORE_MEM,

        LOAD_ARG, 1,
        CONST_INT, i(1),
        LOAD, 1,
        STORE_MEM,

        RETURN,

    label('.main'),
        CONST_NULL,
        CONST_CHAR, c('c'),
        CALL, label('#create_node'), 2,

        CONST_CHAR, c('b'),
        CALL, label('#create_node'), 2,

        CONST_CHAR, c('a'),
        CALL, label('#create_node'), 2,

        CALL, label('#traverse'), 1,

        EXIT,
);

$vm->execute;









