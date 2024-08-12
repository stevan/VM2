#!perl

use v5.40;
use experimental qw[ class ];

class VM::Debugger::Memory {
    field $block  :param :reader;
    field $width  :param :reader = 30;
    field $height :param :reader = 20;

    field $count_fmt;
    field $value_fmt;

    ADJUST {
        $count_fmt = "%05d";
        $value_fmt = "%".($width - 7)."s"; # 5 for the counter, 2 for the divider
    }

    method draw {
        my @words = $block->words;

        my @out;
        push @out => ('=' x $width);
        foreach my $i ( 0 .. $#words ) {
            push @out => sprintf "${count_fmt} ┊${value_fmt}" => $i, ($words[$i] // '~');
        }
        push @out => ('-' x $width);
        push @out => ('Allocated:');
        foreach my $p ( $block->allocated ) {
            push @out => $p->to_string
        }
        push @out => ('-' x $width);
        push @out => ('Freed:');
        foreach my $p ( $block->freed ) {
            push @out => $p->to_string
        }
        push @out => ('=' x $width);
        return @out;
    }
}
