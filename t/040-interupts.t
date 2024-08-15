#!perl

use v5.40;
use experimental qw[ class builtin ];

use VM;
use VM::Assembler::Assembly;
use VM::Debugger;

my $vm = VM->new;

=pod

=cut

$vm->assemble(
    label('.main'),

        GET_CHAR,
        DUP,
        IS_NULL,
        YIELD_IF_TRUE, label('#main'),
        PUT,
        JUMP, label('#main'),

        HALT,
);

$vm->execute(
    VM::Debugger->new( vm => $vm )
);








