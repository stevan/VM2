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
while ( x < 5 ) {
    x = x + 1;
}
x;

=cut

$vm->assemble(
    label('.main'),
        CONST_INT, i(0),

    label('.main.while'),
        LOAD, 0,
        CONST_INT, i(5),
        LT_INT,
        JUMP_IF_FALSE, label('#main.while.break'),

        LOAD, 0,
        CONST_INT, i(1),
        ADD_INT,
        STORE, 0,

        JUMP, label('#main.while'),
    label('.main.while.break'),

        LOAD, 0,
        PUT,
        HALT,
);

$vm->execute;








