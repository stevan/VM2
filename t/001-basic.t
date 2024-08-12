#!perl

use v5.40;
use experimental qw[ class builtin ];

use Scalar::Util ();
use Sub::Util    ();

use VM;
use VM::Assembler::Assembly;

my $vm = VM->new;

$vm->load_code([
    (map { CONST_INT(), i($_) } ( 0 .. 25 )),
    (map { ADD_INT() } ( 0 .. 19 )),
    PRINT,
    HALT
]);

$vm->execute;














