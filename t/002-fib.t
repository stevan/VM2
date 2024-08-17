#!perl

use v5.40;
use experimental qw[ class ];

use Test::More;

use VM;
use VM::Assembler::Assembly;
use VM::Debugger;

my $vm = VM->new;

=pod

int fib (int i) {
    if (i == 0) return 0;
    if (i <  3) return 1;
    return fib( i - 1 ) + fib( i - 2 );
}

=cut

$vm->assemble(
        label('.fib'),
            LOAD_ARG, 0,
            PUSH, i(0),
            EQ_INT,
            JUMP_IF_FALSE, label('#fib.cond_1'),
            PUSH, i(0),
            RETURN,
        label('.fib.cond_1'),
            LOAD_ARG, 0,
            PUSH, i(3),
            LT_INT,
            JUMP_IF_FALSE, label('#fib.cond_2'),
            PUSH, i(1),
            RETURN,
        label('.fib.cond_2'),
            LOAD_ARG, 0,
            PUSH, i(1),
            SUB_INT,
            CALL, label('#fib'), 1,

            LOAD_ARG, 0,
            PUSH, i(2),
            SUB_INT,
            CALL, label('#fib'), 1,

            ADD_INT,
            RETURN,

        label('.main'),
            BREAKPOINT,
            PUSH, i(10),
            CALL, label('#fib'), 1,
            PUT,
            EXIT,
);

$vm->execute;

subtest '... checking the VM state' => sub {
    ok($vm->cpu->completed, '... the CPU completed the code');
    ok(!$vm->cpu->halted, '... the CPU is not halted');
    is($vm->heap->available, $vm->heap->capacity, '... the available space on the heap is equal to the capacity');
    is(scalar $vm->heap->allocated, 0, '... all allocated memory has been freed');
    is(scalar $vm->heap->freed, 0, '... we freed 3 pointer(s)');
    ok(!$vm->sod->is_empty, '... the sod is empty');
    is_deeply(
        [ map $_->value, $vm->sod->buffer ],
        [ 55 ],
        '... the sod contains the expected items'
    );
    ok($vm->sid->is_empty, '... the sid is empty');
};

done_testing;



