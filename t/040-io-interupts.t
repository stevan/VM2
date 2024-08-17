#!perl

use v5.40;
use experimental qw[ class ];

use Test::More;

use constant DEBUG => $ENV{DEBUG} // 0;

use VM;
use VM::Assembler::Assembly;
use VM::Debugger;

my $vm = VM->new;

=pod

    get a character and print it ...

=cut

$vm->assemble(
    label('.main'),
        #BREAKPOINT,
        PUSH, i(20),
        ALLOC_MEM, 1,

        PUSH, i(0), # count up
        PUSH, i(0), # count down

        PUSH, c('?'), PUT,
        PUSH, c(' '), PUT,

    label('.main.getc'),
        HALT,

        GET_CHAR,
        DUP,
        PUSH, c("\n"),
        EQ_CHAR,
        JUMP_IF_TRUE, label('#main.print'),

        BREAKPOINT,

        DUP,
        PUT,

        LOAD, 1,
        LOAD, 0,
        STORE_MEM,

        BREAKPOINT,

        LOAD, 1,
        INC_INT,
        STORE, 1,

        JUMP, label('#main.getc'),

    label('.main.print'),
        PUT,
        PUSH, c('>'), PUT,
        PUSH, c(' '), PUT,

    label('.main.print.loop'),
        BREAKPOINT,
        LOAD, 2,
        LOAD, 0,
        LOAD_MEM,
        PUT,

        LOAD, 2,
        INC_INT,
        DUP,
        STORE, 2,

        LOAD, 1,
        EQ_INT,
        JUMP_IF_FALSE, label('#main.print.loop'),

        PUSH, c("\n"), PUT,
        EXIT,
);

if (DEBUG) {
    $vm->execute;

    subtest '... checking the VM state' => sub {
        ok($vm->cpu->completed, '... the CPU completed the code');
        ok(!$vm->cpu->halted, '... the CPU is not halted');
        is($vm->heap->available, $vm->heap->capacity, '... the available space on the heap is equal to the capacity');
        is(scalar $vm->heap->allocated, 0, '... all allocated memory has been freed');
        is(scalar $vm->heap->freed, 5, '... we freed 3 pointer(s)');
        ok(!$vm->sod->is_empty, '... the sod is empty');
        is_deeply(
            [ map $_->value, $vm->sod->buffer ],
            [ 5, ':', 'h', 'e', 'l', 'l', 'o' ],
            '... the sod contains the expected items'
        );
        ok($vm->sid->is_empty, '... the sid is empty');
    };
} else {
    pass('... not testable yet');
}

done_testing;



