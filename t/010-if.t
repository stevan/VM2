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

x = null;
if ( 10 < 15 ) {
    x = true;
} else {
    x = false;
}
x;

=cut

$vm->assemble(
    label('.main'),
        CONST_NULL,

        CONST_INT, i(10),
        CONST_INT, i(15),
        LT_INT,
        JUMP_IF_FALSE, label('#main.if.else'),
        CONST_TRUE,
        STORE, 0,
        JUMP, label('#main.if.end'),
    label('.main.if.else'),
        CONST_FALSE,
        STORE, 0,
    label('.main.if.end'),

        LOAD, 0,
        HALT,
);

$vm->execute(
    VM::Debugger->new( vm => $vm )
);








