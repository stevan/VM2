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
        LOAD_ARG, 1,
        LOAD_ARG, 0,
        LOAD_MEM,
        DUP,
        IS_NULL,
        JUMP_IF_TRUE, label('#fib.start'),
        RETURN,

    label('.fib.start'),
        LOAD_ARG, 1,
        CONST_INT, i(0),
        EQ_INT,
        JUMP_IF_FALSE, label('#fib.cond_1'),
        CONST_INT, i(0),
        JUMP, label('#fib.return'),

    label('.fib.cond_1'),
        LOAD_ARG, 1,
        CONST_INT, i(3),
        LT_INT,
        JUMP_IF_FALSE, label('#fib.cond_2'),
        CONST_INT, i(1),
        JUMP, label('#fib.return'),

    label('.fib.cond_2'),
        LOAD_ARG, 1,
        CONST_INT, i(1),
        SUB_INT,
        LOAD_ARG, 0,
        CALL, label('#fib'), 2,

        LOAD_ARG, 1,
        CONST_INT, i(2),
        SUB_INT,
        LOAD_ARG, 0,
        CALL, label('#fib'), 2,

        ADD_INT,

    label('.fib.return'),
        DUP,
        LOAD_ARG, 1,
        LOAD_ARG, 0,
        STORE_MEM,
        RETURN,

    label('.main'),
        CONST_INT, i(21),
        ALLOC_MEM, 1,
        DUP,

        CONST_INT, i(20),
        SWAP,
        CALL, label('#fib'), 2,
        PUT,

        LOAD, 0,
        FREE_MEM,
        HALT
);

$vm->execute(
    VM::Debugger->new( vm => $vm )
);








