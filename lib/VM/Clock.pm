#!perl

use v5.40;
use experimental qw[ class ];

class VM::Clock {
    field @on_tick;

    method on_tick ($f) { push @on_tick => $f }

    method tick ($cpu) {
        $cpu->execute;
        $_->($cpu) foreach @on_tick;
    }
}
