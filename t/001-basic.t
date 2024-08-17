#!perl

use v5.40;
use experimental qw[ class ];

use Test::More;

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
        BREAKPOINT,
        PUSH, i(10), # @a
        ALLOC_MEM, 1,

        PUSH, i(0), # $x
        PUSH, i(0), # $y

    label('.main.loop'),
        LOAD, 1, # $x
        LOAD, 2, # $y
        CALL, label('#adder'), 2,
        CALL, label('#doubler'), 1,

        DUP,
        LOAD, 1, # $x
        LOAD, 0, # @a
        STORE_MEM,

        LOAD, 1,
        PUSH, i(1),
        ADD_INT,
        STORE, 1,

        LOAD, 2,
        PUSH, i(1),
        ADD_INT,
        STORE, 2,

        PUSH, i(20),
        LT_INT,
        JUMP_IF_TRUE, label('#main.loop'),

    label('.main.exit'),
        BREAKPOINT,
        LOAD, 0,
        FREE_MEM,
        EXIT,
);

$vm->execute;

subtest '... checking the VM state' => sub {
    ok($vm->cpu->completed, '... the CPU completed the code');
    ok(!$vm->cpu->halted, '... the CPU is not halted');
    is($vm->heap->available, $vm->heap->capacity, '... the available space on the heap is equal to the capacity');
    is(scalar $vm->heap->allocated, 0, '... all allocated memory has been freed');
    is(scalar $vm->heap->freed, 1, '... we freed one pointer');
    ok($vm->sod->is_empty, '... the sod is empty');
    ok($vm->sid->is_empty, '... the sid is empty');
};

done_testing;





