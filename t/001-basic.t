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

my $block = $vm->core->heap;
my $ptr = $block->alloc(5, 1);

{
    my $i = 0;
    while ($ptr->offset < $ptr->length) {
        $block->resolve($ptr) = i(++$i);
        warn join ' : ', $ptr, $block->resolve($ptr), refaddr $block->resolve($ptr);
        $ptr->inc;
    }
}

$vm->execute(
    VM::Debugger->new( vm => $vm )
);








