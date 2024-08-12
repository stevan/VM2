#!perl

use v5.40;
use experimental qw[ class builtin ];

use VM;
use VM::Assembler::Assembly;

use VM::Debugger::Memory;

my $vm = VM->new( heap_size => 10 );

my $block = $vm->core->heap;

my $bdebug = VM::Debugger::Memory->new( vm => $vm );

my $ptr = $block->alloc(5, 1);

$block->resolve($ptr) = i(10);
warn join ' : ', $ptr, $block->resolve($ptr), refaddr $block->resolve($ptr);
$ptr->inc;
$block->resolve($ptr) = i(20);
warn join ' : ', $ptr, $block->resolve($ptr), refaddr $block->resolve($ptr);
$ptr->inc;
$block->resolve($ptr) = i(30);
warn join ' : ', $ptr, $block->resolve($ptr), refaddr $block->resolve($ptr);
$ptr->index(4);
$block->resolve($ptr) = i(40);
warn join ' : ', $ptr, $block->resolve($ptr), refaddr $block->resolve($ptr);

my $ptr2 = $block->alloc(5, 1);

$block->resolve($ptr2) = i(100);
warn join ' : ', $ptr2, $block->resolve($ptr2), refaddr $block->resolve($ptr2);
$ptr2->inc;
$block->resolve($ptr2) = i(200);
warn join ' : ', $ptr2, $block->resolve($ptr2), refaddr $block->resolve($ptr2);
$ptr2->inc;
$block->resolve($ptr2) = i(300);
warn join ' : ', $ptr2, $block->resolve($ptr2), refaddr $block->resolve($ptr2);
$ptr2->index(4);
$block->resolve($ptr2) = i(400);
warn join ' : ', $ptr2, $block->resolve($ptr2), refaddr $block->resolve($ptr2);

say join "\n" => $bdebug->draw;

$block->free( $ptr );

say join "\n" => $bdebug->draw;

my $ptr3 = $block->alloc(5, 1);

say join "\n" => $bdebug->draw;

$block->resolve($ptr3) = i(1000);
warn join ' : ', $ptr3, $block->resolve($ptr3), refaddr $block->resolve($ptr3);
$ptr3->inc;
$block->resolve($ptr3) = i(2000);
warn join ' : ', $ptr3, $block->resolve($ptr3), refaddr $block->resolve($ptr3);
$ptr3->inc;
$block->resolve($ptr3) = i(3000);
warn join ' : ', $ptr3, $block->resolve($ptr3), refaddr $block->resolve($ptr3);
$ptr3->index(4);
$block->resolve($ptr3) = i(4000);
warn join ' : ', $ptr3, $block->resolve($ptr3), refaddr $block->resolve($ptr3);

say join "\n" => $bdebug->draw;

