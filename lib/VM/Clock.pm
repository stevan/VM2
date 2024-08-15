#!perl

use v5.40;
use experimental qw[ class ];

class VM::Clock {
    method tick ($cpu) {
        $cpu->execute;
    }
}
