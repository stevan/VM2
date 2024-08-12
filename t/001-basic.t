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
    label('.main'),
        CONST_TRUE,
        JUMP_IF_FALSE, label('#main.else'),
            CONST_INT, i(10),
            JUMP, label('#main.endif'),
        label('.main.else'),
            CONST_INT, i(20),
        label('.main.endif'),
        PRINT,
        HALT
);

$vm->execute(
    VM::Debugger->new( vm => $vm )
);














