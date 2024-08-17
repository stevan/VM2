#!perl

use v5.40;
use experimental qw[ class ];

use Test::More;

use constant DEBUG => $ENV{DEBUG} // 0;

use VM;
use VM::Assembler::Assembly;
use VM::Debugger::Memory;

my $vm = VM->new( heap_size => 20 );

my $block = $vm->cpu->heap;

my $bdebug;
$bdebug = VM::Debugger::Memory->new( block => $block ) if DEBUG;

is(scalar($block->allocated), 0, '... got the expected number of allocated blocks');
is(scalar($block->freed), 0, '... got the expected number of freed blocks');

my $ptr = $block->alloc(5, 4);
isa_ok($ptr, 'VM::Memory::Pointer');

is(scalar($block->allocated), 1, '... got the expected number of allocated blocks');
is(scalar($block->freed), 0, '... got the expected number of freed blocks');

say join "\n" => $bdebug->draw if DEBUG;

try {
    my $i = 0;
    while ($ptr->offset < $ptr->length) {
        my $sptr = $block->resolve($ptr);
        isa_ok($sptr, 'VM::Memory::Pointer');

        warn join ' : ' => $ptr,  refaddr $ptr if DEBUG;
        warn join ' : ' => $sptr, refaddr $sptr if DEBUG;


        my $j = 0;
        while ($sptr->offset < $sptr->length) {
            $block->resolve($sptr) = i($i + ($j * 100));
            $j++;
            warn join ' : ', $sptr, $block->resolve($sptr), refaddr $block->resolve($sptr) if DEBUG;
            $sptr->inc;
        }
        $i++;
        warn join ' : ', $ptr, $block->resolve($ptr), refaddr $block->resolve($ptr) if DEBUG;
        $ptr->inc;
    }
    pass('... no exceptions thrown');
} catch($e) {
    fail("Unexpected exception: $e");
}

say join "\n" => $bdebug->draw if DEBUG;

done_testing;
