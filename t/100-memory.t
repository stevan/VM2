#!perl

use v5.40;
use experimental qw[ class builtin ];

use VM;
use VM::Memory;
use VM::Assembler::Assembly;

my $block = VM::Memory::Block->new( capacity => 10 );

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
#$ptr2->inc;
#warn join ' : ', $ptr2, $block->resolve($ptr2), refaddr $block->resolve($ptr2);

say join "\n" => map { $_ // '~' } $block->dump->@*;

$block->free( $ptr );

say join "\n" => map { $_ // '~' } $block->dump->@*;


