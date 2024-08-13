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
        CONST_INT, i(10),
        CONST_INT, i(15),
        CALL, label('#adder'), 2,
        CALL, label('#doubler'), 1,
        PRINT,
        HALT
);

$vm->execute(
    VM::Debugger->new( vm => $vm )
);








