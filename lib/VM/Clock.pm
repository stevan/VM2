#!perl

use v5.40;
use experimental qw[ class ];

use importer 'Time::HiRes' => qw[ time ];

class VM::Clock {
    field @timings :reader;

    method tick ($cpu) {
        my $start = time;
        $cpu->execute;
        push @timings => $cpu->code_index($cpu->ci), (time - $start);
    }
}
