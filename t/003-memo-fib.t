#!perl

use v5.40;
use experimental qw[ class ];

use Test::More;

use VM;
use VM::Assembler::Assembly;
use VM::Debugger;

my $vm = VM->new;

$vm->assemble(
    label('.fib'),
        LOAD_ARG, 0,
        PUSH, i(1),
        ADD_INT,
        ALLOC_MEM, 1,
        DUP,

        LOAD_ARG, 0,
        SWAP,
        CALL, label('#fib.2'), 2,

        SWAP,
        FREE_MEM,
        RETURN,

    label('.fib.2'),
        LOAD_ARG, 1,
        LOAD_ARG, 0,
        LOAD_MEM,
        DUP,
        IS_NULL,
        JUMP_IF_TRUE, label('#fib.2.start'),
        JUMP, label('#fib.2.return'),

    label('.fib.2.start'),
        LOAD_ARG, 1,
        PUSH, i(0),
        EQ_INT,
        JUMP_IF_FALSE, label('#fib.2.cond.1'),
        PUSH, i(0),
        JUMP, label('#fib.2.memoize'),

    label('.fib.2.cond.1'),
        LOAD_ARG, 1,
        PUSH, i(3),
        LT_INT,
        JUMP_IF_FALSE, label('#fib.2.cond.2'),
        PUSH, i(1),
        JUMP, label('#fib.2.memoize'),

    label('.fib.2.cond.2'),
        LOAD_ARG, 1,
        PUSH, i(1),
        SUB_INT,
        LOAD_ARG, 0,
        CALL, label('#fib.2'), 2,

        LOAD_ARG, 1,
        PUSH, i(2),
        SUB_INT,
        LOAD_ARG, 0,
        CALL, label('#fib.2'), 2,

        ADD_INT,

    label('.fib.2.memoize'),
        DUP,
        LOAD_ARG, 1,
        LOAD_ARG, 0,
        STORE_MEM,
    label('.fib.2.return'),
        RETURN,

    label('.main'),
        BREAKPOINT,
        PUSH, i(10),
        CALL, label('#fib'), 1,
        PUT,
        BREAKPOINT,
        EXIT,
);

$vm->execute;

subtest '... checking the VM state' => sub {
    ok($vm->cpu->completed, '... the CPU completed the code');
    ok(!$vm->cpu->halted, '... the CPU is not halted');
    is($vm->heap->available, $vm->heap->capacity, '... the available space on the heap is equal to the capacity');
    is(scalar $vm->heap->allocated, 0, '... all allocated memory has been freed');
    is(scalar $vm->heap->freed, 1, '... we freed one pointer');
    ok(!$vm->sod->is_empty, '... the sod is empty');
    is_deeply(
        [ map $_->value, $vm->sod->buffer ],
        [ 55 ],
        '... the sod contains the expected items'
    );
    ok($vm->sid->is_empty, '... the sid is empty');
};

done_testing;


