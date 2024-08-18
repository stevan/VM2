#!perl

use v5.40;
use experimental qw[ class ];

use Test::More;

use VM;
use VM::Assembler::Assembly;
use VM::Debugger;

my $vm = VM->new;

=pod

my $input = '3637829';

sub find_number ($char) {
    return 0 if $char eq '0';
    return 1 if $char eq '1';
    return 2 if $char eq '2';
    return 3 if $char eq '3';
    return 4 if $char eq '4';
    return 5 if $char eq '5';
    return 6 if $char eq '6';
    return 7 if $char eq '7';
    return 8 if $char eq '8';
    return 9 if $char eq '9';
    die "WTF is ($char)!";
}

sub find_multiplier ($place) {
    return 1 if $place == 1;
    return 10 if $place == 2;
    return 100 if $place == 3;
    return 1000 if $place == 4;
    return 10000 if $place == 5;
    return 100000 if $place == 6;
    return 1000000 if $place == 7;
    return 10000000 if $place == 8;
    return 100000000 if $place == 9;
    die "OVERFLOW($place)!";
}

sub parse_int ($length, @chars) {
    my $acc = 0;
    for ( my $i = 0; $i < $length; $i++ ) {
        my $int = find_number( $chars[$i] );
        my $mul = find_multiplier( $length - $i );
        #warn $chars[$i]." & ".($length - $i);
        #warn "$int * $mul";
        $acc += $int * $mul;
    }
    return $acc;
}

say parse_int(length($input), split '' => $input);

=cut

$vm->assemble(
   label('.find_number'),
        PUSH, i(0),
        PUSH, c('0'),
        label('.find_number.loop'),
            LOAD, 2,
            LOAD_ARG, 0,
            EQ_CHAR,
            JUMP_IF_TRUE, label('#find_number.return'),
                LOAD,2,
                    INC_CHAR,
                    DUP,
                    PUSH, c('9'),
                    GT_CHAR,
                    JUMP_IF_TRUE, label('#find_number.error'),
                STORE, 2,
                LOAD, 1,
                    INC_INT,
                STORE, 1,
                JUMP, label('#find_number.loop'),
        label('.find_number.error'),
            CONST_NULL,
            RETURN,
        label('.find_number.return'),
            LOAD, 1,
            RETURN,

    label('.find_multipler'),
        PUSH, i(1),
        DUP,

    label('.find_multipler.loop'),
        LOAD, 2,
        LOAD_ARG, 0,
        EQ_INT,
        JUMP_IF_TRUE, label('#find_multipler.return'),
            LOAD, 1,
                PUSH, i(10),
                MUL_INT,
            STORE, 1,
            LOAD, 2,
                INC_INT,
            STORE, 2,
            JUMP, label('#find_multipler.loop'),

    label('.find_multipler.return'),
        LOAD, 1,
        RETURN,

    label('.parse_int'),
        PUSH, i(0),  # acc
        PUSH, i(0),  # i

        LOAD_ARG, 1, # chars
        LOAD_ARG, 2,
        LOAD_ARG, 3,
        LOAD_ARG, 4,
        LOAD_ARG, 5,
        LOAD_ARG, 6,

    label('.parse_int.loop'),
        LOAD, 2,
        LOAD_ARG, 0,
        EQ_INT,
        JUMP_IF_TRUE, label('#parse_int.return'),

            CALL, label('#find_number'), 1,

            LOAD_ARG, 0,
            LOAD, 2,
            SUB_INT,
            CALL, label('#find_multipler'), 1,

                BREAKPOINT,
            MUL_INT,
                BREAKPOINT,
            LOAD, 1,
            ADD_INT,
                BREAKPOINT,
            STORE, 1,
            BREAKPOINT,
            LOAD, 2,
                INC_INT,
            STORE, 2,
            JUMP, label('#parse_int.loop'),

    label('.parse_int.return'),
        LOAD, 1,
        RETURN,

    label('.main'),
        BREAKPOINT,

        PUSH, c('5'),
        PUSH, c('9'),
        PUSH, c('0'),
        PUSH, c('3'),
        PUSH, c('9'),
        PUSH, c('4'),
        PUSH, i(6),
        CALL, label('#parse_int'), 7,
        PUT,

        EXIT,
);

$vm->execute;

say $vm->sod->buffer;

subtest '... checking the VM state' => sub {
    ok($vm->cpu->completed, '... the CPU completed the code');
    ok(!$vm->cpu->halted, '... the CPU is not halted');
    is($vm->heap->available, $vm->heap->capacity, '... the available space on the heap is equal to the capacity');
    is(scalar $vm->heap->allocated, 0, '... all allocated memory has been freed');
    is(scalar $vm->heap->freed, 0, '... we freed one pointer');
    ok(!$vm->sod->is_empty, '... the sod is empty');
    is_deeply(
        [ map $_->value, $vm->sod->buffer ],
        [ 590394 ],
        '... the sod contains the expected items'
    );
    ok($vm->sid->is_empty, '... the sid is empty');
};

done_testing;





