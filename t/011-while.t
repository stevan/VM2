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
while ( x < 5 ) {
    x = x + 1;
}
x;

=cut

$vm->assemble(
    label('.main'),
        BREAKPOINT,
        PUSH, i(0),

    label('.main.while'),
        LOAD, 0,
        PUSH, i(5),
        LT_INT,
        JUMP_IF_FALSE, label('#main.while.break'),

        LOAD, 0,
        PUSH, i(1),
        ADD_INT,
        STORE, 0,
        BREAKPOINT,

        JUMP, label('#main.while'),
    label('.main.while.break'),

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
        [ 5 ],
        '... the sod contains the expected items'
    );
    ok($vm->sid->is_empty, '... the sid is empty');
};


