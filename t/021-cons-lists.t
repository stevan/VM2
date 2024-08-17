#!perl

use v5.40;
use experimental qw[ class ];

use Test::More;

use VM;
use VM::Assembler::Assembly;
use VM::Debugger;

my $vm = VM->new;

=pod

use Data::Dumper;

sub rev ($n) {
    warn Dumper { n => $n };
    if ( not(defined $n->[1]) ) {
        return $n;
    }
    else {
        my $r = rev($n->[1]);
        $n->[1]->[1] = $n;
        $n->[1] = undef;
        return $r;
    }
}

die Dumper { RESULT => rev( ['o', ['l', ['l', ['e', ['h', undef]]]]] ) };

=cut

$vm->assemble(
    label('.reverse'),
        LOAD_ARG, 0,
        CALL, label('#tail'), 1,
        IS_NULL,
        JUMP_IF_FALSE, label('#reverse.cond'),
        LOAD_ARG, 0,
        RETURN,
    label('.reverse.cond'),
        LOAD_ARG, 0,
        CALL, label('#tail'), 1,
        CALL, label('#reverse'), 1,

        LOAD_ARG, 0,
        PUSH, i(1),
        LOAD_ARG, 0,
        CALL, label('#tail'), 1,
        STORE_MEM,

        CONST_NULL,
        PUSH, i(1),
        LOAD_ARG, 0,
        STORE_MEM,

        RETURN,

   label('.length'),
       LOAD_ARG, 0,
       CALL, label('#tail'), 1,
       DUP,
       IS_NULL,
       JUMP_IF_TRUE, label('#length.cond'),
       CALL, label('#length'), 1,
       PUSH, i(1),
       ADD_INT,
       RETURN,
   label('.length.cond'),
       PUSH, i(1),
       RETURN,

    label('.print'),
        LOAD_ARG, 0,
        CALL, label('#head'), 1,
        PUT,
        LOAD_ARG, 0,
        CALL, label('#tail'), 1,
        DUP,
        IS_NULL,
        JUMP_IF_TRUE, label('#print.exit'),
        CALL, label('#print'), 1,
    label('.print.exit'),
        RETURN,

    label('.free'),
        BREAKPOINT,
        LOAD_ARG, 0,
        CALL, label('#tail'), 1,
        DUP,

        LOAD_ARG, 0,
        FREE_MEM,

        IS_NULL,
        JUMP_IF_TRUE, label('#free.exit'),
        CALL, label('#free'), 1,
    label('.free.exit'),
        BREAKPOINT,
        RETURN,

    label('.head'),
        PUSH, i(0),
        LOAD_ARG, 0,
        LOAD_MEM,
        RETURN,

    label('.tail'),
        PUSH, i(1),
        LOAD_ARG, 0,
        LOAD_MEM,
        RETURN,

    label('.cons'),
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
        PUSH, c('h'),
        CALL, label('#cons'), 2,

        PUSH, c('e'),
        CALL, label('#cons'), 2,

        PUSH, c('l'),
        CALL, label('#cons'), 2,

        PUSH, c('l'),
        CALL, label('#cons'), 2,

        PUSH, c('o'),
        CALL, label('#cons'), 2,

        DUP,
        CALL, label('#length'), 1,
        PUT,
        PUSH, c(':'),
        PUT,

        CALL, label('#reverse'), 1,
        DUP,
        CALL, label('#print'), 1,
        POP,
        BREAKPOINT,
        CALL, label('#free'), 1,

        BREAKPOINT,

        EXIT,
);

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

done_testing;







