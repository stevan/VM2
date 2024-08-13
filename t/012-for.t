#!perl

use v5.40;
use experimental qw[ class builtin ];

use Scalar::Util ();
use Sub::Util    ();

use VM;
use VM::Assembler::Assembly;
use VM::Debugger;

my $vm = VM->new;

=pod

x = 0;
for ( i = 0; i < 5; i = i + 1 ) {
    x = x + i;
}
x;

=cut

$vm->assemble(
    label('.main'),

    CONST_INT, i(0), # x
    CONST_INT, i(0), # i

    label('.main.for'),
        label('.main.for.init'),
            CONST_INT, i(0),
            STORE, 1,
            JUMP, label('#main.for.body'),
        label('.main.for.cond'),
            LOAD, 1,
            CONST_INT, i(5),
            LT_INT,
            JUMP_IF_FALSE, label('#main.for.end'),
            LOAD, 1,
            CONST_INT, i(1),
            ADD_INT,
            STORE, 1,
        label('.main.for.body'),
            LOAD, 0,
            LOAD, 1,
            ADD_INT,
            STORE, 0,
            JUMP, label('#main.for.cond'),
        label('.main.for.end'),

        LOAD, 0,
        PRINT,
        HALT,
);

$vm->execute(
    VM::Debugger->new( vm => $vm )
);








