#!perl

use v5.40;
use experimental qw[ class builtin ];

use VM;
use VM::Assembler::Assembly;
use VM::Debugger::Memory;

my $vm = VM->new( heap_size => 20 );

my $block = $vm->core->heap;

my $bdebug = VM::Debugger::Memory->new( block => $block );

my $ptr = $block->alloc(5, 4);

say join "\n" => $bdebug->draw;

{
    my $i = 0;
    while ($ptr->offset < $ptr->length) {
        my $sptr = $block->resolve($ptr);
        warn join ' : ' => $ptr,  refaddr $ptr;
        warn join ' : ' => $sptr, refaddr $sptr;


        my $j = 0;
        while ($sptr->offset < $sptr->length) {
            $block->resolve($sptr) = i($i + ($j * 100));
            $j++;
            warn join ' : ', $sptr, $block->resolve($sptr), refaddr $block->resolve($sptr);
            $sptr->inc;
        }
        $i++;
        warn join ' : ', $ptr, $block->resolve($ptr), refaddr $block->resolve($ptr);
        $ptr->inc;
    }
}

say join "\n" => $bdebug->draw;
