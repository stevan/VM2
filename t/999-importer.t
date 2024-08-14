#!perl

use v5.40;
use experimental qw[ class builtin ];

use Test::More;

{
    use importer 'List::Util' => qw[ sum ];

    try {
        is(sum( 1 .. 5 ), 15, '... import worked');
    } catch ($e) {
        fail('... this should not happen');
    }
}

try {
    sum( 1 .. 5 ) && fail('... this is bad, it should not happen');
} catch ($e) {
    pass('... this is what should happen');
}

done_testing;
