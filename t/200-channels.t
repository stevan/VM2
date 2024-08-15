#!perl

use v5.40;
use experimental qw[ class builtin ];

use VM;
use VM::Assembler::Assembly;


my $ch = VM::Channel->new;

$ch->put( i(1) );
$ch->put( c('h') );
$ch->put( i(2) );
$ch->put( f(0.01) );
$ch->put( f(0.02) );
$ch->put( c('e') );
$ch->put( f(0.03) );
$ch->put( i(3) );
$ch->put( c('l') );
$ch->put( c('l') );
$ch->put( i(4) );
$ch->put( f(0.04) );
$ch->put( c('0') );
$ch->put( f(0.05) );
$ch->put( i(5) );

say join ', ' => $ch->buffer;

say $ch->has(VM::Types->INT) ? 'Has INT' : 'No INT';
say $ch->has(VM::Types->CHAR) ? 'Has CHAR' : 'No CHAR';
say $ch->has(VM::Types->FLOAT) ? 'Has FLOAT' : 'No FLOAT';

for (
    my $int = $ch->get(VM::Types->INT);
    !($int isa VM::Value::NULL);
    $int = $ch->get(VM::Types->INT)
) {
    say $int;
    say join ', ' => $ch->buffer;
}

say $ch->has(VM::Types->INT) ? 'Has INT' : 'No INT';
say $ch->has(VM::Types->CHAR) ? 'Has CHAR' : 'No CHAR';
say $ch->has(VM::Types->FLOAT) ? 'Has FLOAT' : 'No FLOAT';

for (
    my $char = $ch->get(VM::Types->CHAR);
    !($char isa VM::Value::NULL);
    $char = $ch->get(VM::Types->CHAR)
) {
    say $char;
    say join ', ' => $ch->buffer;
}

say $ch->has(VM::Types->INT) ? 'Has INT' : 'No INT';
say $ch->has(VM::Types->CHAR) ? 'Has CHAR' : 'No CHAR';
say $ch->has(VM::Types->FLOAT) ? 'Has FLOAT' : 'No FLOAT';

for (
    my $float = $ch->get(VM::Types->FLOAT);
    !($float isa VM::Value::NULL);
    $float = $ch->get(VM::Types->FLOAT)
) {
    say $float;
    say join ', ' => $ch->buffer;
}

say $ch->has(VM::Types->INT) ? 'Has INT' : 'No INT';
say $ch->has(VM::Types->CHAR) ? 'Has CHAR' : 'No CHAR';
say $ch->has(VM::Types->FLOAT) ? 'Has FLOAT' : 'No FLOAT';













