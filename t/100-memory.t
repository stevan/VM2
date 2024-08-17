#!perl

use v5.40;
use experimental qw[ class ];

use Test::More;

use constant DEBUG => $ENV{DEBUG} // 0;

use VM;
use VM::Assembler::Assembly;
use VM::Debugger::Memory;

my $vm = VM->new( heap_size => 10 );

my $block = $vm->cpu->heap;

my $bdebug;
$bdebug = VM::Debugger::Memory->new( block => $block ) if DEBUG;

is(scalar($block->allocated), 0, '... got the expected number of allocated blocks');
is(scalar($block->freed), 0, '... got the expected number of freed blocks');

my $ptr = $block->alloc(5, 1);
isa_ok($ptr, 'VM::Memory::Pointer');

is(scalar($block->allocated), 1, '... got the expected number of allocated blocks');
is(scalar($block->freed), 0, '... got the expected number of freed blocks');

try {
    my $i = 0;
    while ($ptr->offset < $ptr->length) {
        $block->resolve($ptr) = i(++$i);
        #warn join ' : ', $ptr, $block->resolve($ptr), refaddr $block->resolve($ptr);
        $ptr->inc;
    }
    pass('... no exceptions thrown');
} catch($e) {
    fail("Unexpected exception: $e");
}

my $ptr2 = $block->alloc(5, 1);
isa_ok($ptr2, 'VM::Memory::Pointer');

is(scalar($block->allocated), 2, '... got the expected number of allocated blocks');
is(scalar($block->freed), 0, '... got the expected number of freed blocks');

try {
    my $i = 0;
    while ($ptr2->offset < $ptr2->length) {
        $block->resolve($ptr2) = i(++$i);
        #warn join ' : ', $ptr2, $block->resolve($ptr2), refaddr $block->resolve($ptr2);
        $ptr2->inc;
    }
    pass('... no exceptions thrown');
} catch($e) {
    fail("Unexpected exception: $e");
}

say join "\n" => $bdebug->draw if DEBUG;

$block->free( $ptr );

is(scalar($block->allocated), 1, '... got the expected number of allocated blocks');
is(scalar($block->freed), 1, '... got the expected number of freed blocks');

say join "\n" => $bdebug->draw if DEBUG;

my $ptr3 = $block->alloc(5, 1);
isa_ok($ptr3, 'VM::Memory::Pointer');

is(scalar($block->allocated), 2, '... got the expected number of allocated blocks');
is(scalar($block->freed), 0, '... got the expected number of freed blocks (0 because of reused pointer)');

say join "\n" => $bdebug->draw if DEBUG;

try {
    my $i = 0;
    while ($ptr3->offset < $ptr3->length) {
        $block->resolve($ptr3) = i(++$i);
        #warn join ' : ', $ptr3, $block->resolve($ptr3), refaddr $block->resolve($ptr3);
        $ptr3->inc;
    }
    pass('... no exceptions thrown');
} catch($e) {
    fail("Unexpected exception: $e");
}

say join "\n" => $bdebug->draw if DEBUG;

done_testing;

