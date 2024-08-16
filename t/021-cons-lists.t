#!perl

use v5.40;
use experimental qw[ class builtin ];

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
        CONST_INT, i(1),
        LOAD_ARG, 0,
        CALL, label('#tail'), 1,
        STORE_MEM,

        CONST_NULL,
        CONST_INT, i(1),
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
       CONST_INT, i(1),
       ADD_INT,
       RETURN,
   label('.length.cond'),
       CONST_INT, i(1),
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

    label('.head'),
        CONST_INT, i(0),
        LOAD_ARG, 0,
        LOAD_MEM,
        RETURN,

    label('.tail'),
        CONST_INT, i(1),
        LOAD_ARG, 0,
        LOAD_MEM,
        RETURN,

    label('.cons'),
        CONST_INT, i(2),
        ALLOC_MEM, 1,

        LOAD_ARG, 0,
        CONST_INT, i(0),
        LOAD, 1,
        STORE_MEM,

        LOAD_ARG, 1,
        CONST_INT, i(1),
        LOAD, 1,
        STORE_MEM,

        RETURN,

    label('.main'),
        CONST_NULL,
        CONST_CHAR, c('h'),
        CALL, label('#cons'), 2,

        CONST_CHAR, c('e'),
        CALL, label('#cons'), 2,

        CONST_CHAR, c('l'),
        CALL, label('#cons'), 2,

        CONST_CHAR, c('l'),
        CALL, label('#cons'), 2,

        CONST_CHAR, c('o'),
        CALL, label('#cons'), 2,

        DUP,
        CALL, label('#length'), 1,
        PUT,
        CONST_CHAR, c(':'),
        PUT,

        CALL, label('#reverse'), 1,
        CALL, label('#print'), 1,

        EXIT,
);

$vm->execute;









