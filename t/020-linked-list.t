#!perl

use v5.40;
use experimental qw[ class ];

use Test::More;

use VM;
use VM::Assembler::Assembly;
use VM::Debugger;

my $vm = VM->new;

$vm->assemble(
    label('.traverse'),
        PUSH, i(0),
        LOAD_ARG, 0,
        LOAD_MEM,
        PUT,
        PUSH, i(1),
        LOAD_ARG, 0,
        LOAD_MEM,
        DUP,
        IS_NULL,
        JUMP_IF_TRUE, label('#traverse.exit'),
        CALL, label('#traverse'), 1,
    label('.traverse.exit'),
        RETURN,

    label('.free_node'),
        BREAKPOINT,
        PUSH, i(1),
        LOAD_ARG, 0,
        LOAD_MEM,
        DUP,

        LOAD_ARG, 0,
        FREE_MEM,

        IS_NULL,
        JUMP_IF_TRUE, label('#free_node.exit'),
        CALL, label('#free_node'), 1,
    label('.free_node.exit'),
        BREAKPOINT,
        RETURN,

    label('.create_node'),
        PUSH, i(2),
        ALLOC_MEM, 1,

        LOAD_ARG, 0,
        PUSH, i(0),
        LOAD, 1,
        STORE_MEM,

        LOAD_ARG, 1,
        PUSH, i(1),
        LOAD, 1,
        STORE_MEM,

        RETURN,

    label('.main'),
        BREAKPOINT,
        CONST_NULL,
        PUSH, c('c'),
        CALL, label('#create_node'), 2,

        PUSH, c('b'),
        CALL, label('#create_node'), 2,

        PUSH, c('a'),
        CALL, label('#create_node'), 2,

        LOAD, 0,
        CALL, label('#traverse'), 1,

        LOAD, 0,
        CALL, label('#free_node'), 1,

        EXIT,
);

$vm->execute;

subtest '... checking the VM state' => sub {
    ok($vm->cpu->completed, '... the CPU completed the code');
    ok(!$vm->cpu->halted, '... the CPU is not halted');
    is($vm->heap->available, $vm->heap->capacity, '... the available space on the heap is equal to the capacity');
    is(scalar $vm->heap->allocated, 0, '... all allocated memory has been freed');
    is(scalar $vm->heap->freed, 3, '... we freed 3 pointer(s)');
    ok(!$vm->sod->is_empty, '... the sod is empty');
    is_deeply(
        [ map $_->value, $vm->sod->buffer ],
        [ 'a', 'b', 'c' ],
        '... the sod contains the expected items'
    );
    ok($vm->sid->is_empty, '... the sid is empty');
};

done_testing;








