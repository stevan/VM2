#!perl

use v5.40;
use experimental qw[ class ];

use Test::More;

use VM;
use VM::Assembler::Assembly;
use VM::Debugger;

my $vm = VM->new;

=pod

x = null;
if ( 10 < 15 ) {
    x = true;
} else {
    x = false;
}
x;

=cut

$vm->assemble(
    label('.main'),
        BREAKPOINT,
        CONST_NULL,

        PUSH, i(10),
        PUSH, i(15),
        LT_INT,
        JUMP_IF_FALSE, label('#main.if.else'),
        CONST_TRUE,
        STORE, 0,
        JUMP, label('#main.if.end'),
    label('.main.if.else'),
        CONST_FALSE,
        STORE, 0,
    label('.main.if.end'),

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
        [ true ],
        '... the sod contains the expected items'
    );
    ok($vm->sid->is_empty, '... the sid is empty');
};

done_testing;





