#!perl

use v5.40;
use experimental qw[ class builtin ];

use VM;
use VM::Assembler::Assembly;

use VM::Debugger::Memory;

my $vm = VM->new( heap_size => 10 );

my $block = $vm->cpu->heap;

my $bdebug = VM::Debugger::Memory->new( block => $block );

my $ptr = $block->alloc(5, 1);

{
    my $i = 0;
    while ($ptr->offset < $ptr->length) {
        $block->resolve($ptr) = i(++$i);
        warn join ' : ', $ptr, $block->resolve($ptr), refaddr $block->resolve($ptr);
        $ptr->inc;
    }
}

my $ptr2 = $block->alloc(5, 1);

{
    my $i = 0;
    while ($ptr2->offset < $ptr2->length) {
        $block->resolve($ptr2) = i(++$i);
        warn join ' : ', $ptr2, $block->resolve($ptr2), refaddr $block->resolve($ptr2);
        $ptr2->inc;
    }
}

say join "\n" => $bdebug->draw;

$block->free( $ptr );

say join "\n" => $bdebug->draw;

my $ptr3 = $block->alloc(5, 1);

say join "\n" => $bdebug->draw;

{
    my $i = 0;
    while ($ptr3->offset < $ptr3->length) {
        $block->resolve($ptr3) = i(++$i);
        warn join ' : ', $ptr3, $block->resolve($ptr3), refaddr $block->resolve($ptr3);
        $ptr3->inc;
    }
}

say join "\n" => $bdebug->draw;

