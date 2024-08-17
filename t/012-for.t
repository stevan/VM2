#!perl

use v5.40;
use experimental qw[ class ];

use Test::More;

use VM;
use VM::Assembler::Assembly;
use VM::Debugger;

my $vm = VM->new;

=pod

x = 0;
for ( i = 0; i < 5; i = i + 1 ) {
    x = x + i;
}
x;

=cut

$vm->assemble(
    label('.main'),

    PUSH, i(0), # x
    PUSH, i(0), # i

    label('.main.for'),
        label('.main.for.init'),
            PUSH, i(0),
            STORE, 1,
            JUMP, label('#main.for.body'),
        label('.main.for.cond'),
            LOAD, 1,
            PUSH, i(5),
            LT_INT,
            JUMP_IF_FALSE, label('#main.for.end'),
            LOAD, 1,
            PUSH, i(1),
            ADD_INT,
            STORE, 1,
        label('.main.for.body'),
            LOAD, 0,
            LOAD, 1,
            ADD_INT,
            STORE, 0,
            JUMP, label('#main.for.cond'),
        label('.main.for.end'),

        LOAD, 0,
        PUT,
        EXIT,
);

$vm->execute;


subtest '... checking the VM state' => sub {
    ok($vm->cpu->completed, '... the CPU completed the code');
    ok(!$vm->cpu->halted, '... the CPU is not halted');
    is($vm->heap->available, $vm->heap->capacity, '... the available space on the heap is equal to the capacity');
    is(scalar $vm->heap->allocated, 0, '... all allocated memory has been freed');
    is(scalar $vm->heap->freed, 0, '... we freed one pointer');
    ok(!$vm->sod->is_empty, '... the sod is empty');
    is_deeply(
        [ map $_->value, $vm->sod->buffer ],
        [ 15 ],
        '... the sod contains the expected items'
    );
    ok($vm->sid->is_empty, '... the sid is empty');
};






