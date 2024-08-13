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
            CONST_INT, i(0),
            EQ_INT,
            JUMP_IF_FALSE, label('#fib.cond_1'),
            CONST_INT, i(0),
            RETURN,
        label('.fib.cond_1'),
            LOAD_ARG, 0,
            CONST_INT, i(3),
            LT_INT,
            JUMP_IF_FALSE, label('#fib.cond_2'),
            CONST_INT, i(1),
            RETURN,
        label('.fib.cond_2'),
            LOAD_ARG, 0,
            CONST_INT, i(1),
            SUB_INT,
            CALL, label('#fib'), 1,

            LOAD_ARG, 0,
            CONST_INT, i(2),
            SUB_INT,
            CALL, label('#fib'), 1,

            ADD_INT,
            RETURN,

        label('.main'),
            CONST_INT, i(3),
            CALL, label('#fib'), 1,

            #FORMAT_STR, "VM: %d", 1,
            #DUP,
            PRINT,
            #FREE_MEM,
            HALT,
);

$vm->execute(
    VM::Debugger->new( vm => $vm )
);


