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



        HALT,
);

$vm->execute;








