#!perl

use v5.40;
use experimental qw[ class builtin ];

use Scalar::Util ();
use Sub::Util    ();

use VM;
use VM::Assembler::Assembly;
use VM::Debugger;

my $vm = VM->new;

$vm->sid->put(c($_)) foreach split '' => '[1]';

my $debugger = VM::Debugger->new( vm => $vm ) if $ENV{'DEBUG'};

=pod

TODO:
This needs work, it is not anywhere near
finished or even a sensible start.


=cut

$vm->assemble(
    label('.parse'),
        GET_CHAR,

    label('.parse.switch'),
        LOAD, 1,
        CONST_CHAR, c('['),
        EQ_CHAR,
        JUMP_IF_TRUE, label('#parse.switch.array.start'),

        LOAD, 1,
        CONST_CHAR, c(']'),
        EQ_CHAR,
        JUMP_IF_TRUE, label('#parse.switch.array.end'),

        LOAD, 1,
        CONST_CHAR, c('0'),
        GE_CHAR,
        LOAD, 1,
        CONST_CHAR, c('9'),
        LE_CHAR,
        AND,
        JUMP_IF_TRUE, label('#parse.switch.number'),

    label('.parse.switch.array.start'),
        CONST_CHAR, c('<'),
        PUT,
        JUMP, label('#parse.switch.break'),

    label('.parse.switch.array.end'),
        CONST_CHAR, c('>'),
        PUT,
        JUMP, label('#parse.switch.break'),

    label('.parse.switch.number'),
        LOAD, 1,
        PUT,
        CONST_CHAR, c(','),
        PUT,
        JUMP, label('#parse.switch.break'),

    label('.parse.switch.break'),
        GET_CHAR,
        DUP,
        IS_NULL,
        JUMP_IF_TRUE, label('#parse.switch.exit'),
        STORE, 1,
        JUMP, label('#parse.switch'),

    label('.parse.switch.exit'),
        RETURN,

    label('.main'),
        CALL, label('#parse'), 0,
        HALT,
);

$vm->execute;








