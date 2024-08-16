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
    label('.fib'),
        LOAD_ARG, 0,
        CONST_INT, i(1),
        ADD_INT,
        ALLOC_MEM, 1,
        DUP,

        LOAD_ARG, 0,
        SWAP,
        CALL, label('#fib.2'), 2,

        SWAP,
        FREE_MEM,
        RETURN,

    label('.fib.2'),
        LOAD_ARG, 1,
        LOAD_ARG, 0,
        LOAD_MEM,
        DUP,
        IS_NULL,
        JUMP_IF_TRUE, label('#fib.2.start'),
        JUMP, label('#fib.2.return'),

    label('.fib.2.start'),
        LOAD_ARG, 1,
        CONST_INT, i(0),
        EQ_INT,
        JUMP_IF_FALSE, label('#fib.2.cond.1'),
        CONST_INT, i(0),
        JUMP, label('#fib.2.memoize'),

    label('.fib.2.cond.1'),
        LOAD_ARG, 1,
        CONST_INT, i(3),
        LT_INT,
        JUMP_IF_FALSE, label('#fib.2.cond.2'),
        CONST_INT, i(1),
        JUMP, label('#fib.2.memoize'),

    label('.fib.2.cond.2'),
        LOAD_ARG, 1,
        CONST_INT, i(1),
        SUB_INT,
        LOAD_ARG, 0,
        CALL, label('#fib.2'), 2,

        LOAD_ARG, 1,
        CONST_INT, i(2),
        SUB_INT,
        LOAD_ARG, 0,
        CALL, label('#fib.2'), 2,

        ADD_INT,

    label('.fib.2.memoize'),
        DUP,
        LOAD_ARG, 1,
        LOAD_ARG, 0,
        STORE_MEM,
    label('.fib.2.return'),
        RETURN,

    label('.main'),
        CONST_INT, i(10),
        CALL, label('#fib'), 1,
        PUT,
        EXIT,
);

$vm->execute;

