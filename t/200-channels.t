#!perl

use v5.40;
use experimental qw[ class ];

use Test::More;

use constant DEBUG => $ENV{DEBUG} // 0;

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

say join ', ' => $ch->buffer if DEBUG;

ok($ch->has(VM::Types->INT),   '... has INT');
ok($ch->has(VM::Types->CHAR),  '... has CHAR');
ok($ch->has(VM::Types->FLOAT), '... has FLOAT');

for (
    my $int = $ch->get(VM::Types->INT);
    !($int isa VM::Value::NULL);
    $int = $ch->get(VM::Types->INT)
) {
    isa_ok($int, 'VM::Value::INT');
    say $int if DEBUG;
    say join ', ' => $ch->buffer if DEBUG;
}

ok(!$ch->has(VM::Types->INT),   '... no more INT');
ok($ch->has(VM::Types->CHAR),  '... has CHAR');
ok($ch->has(VM::Types->FLOAT), '... has FLOAT');

for (
    my $char = $ch->get(VM::Types->CHAR);
    !($char isa VM::Value::NULL);
    $char = $ch->get(VM::Types->CHAR)
) {
    isa_ok($char, 'VM::Value::CHAR');
    say $char if DEBUG;
    say join ', ' => $ch->buffer if DEBUG;
}

ok(!$ch->has(VM::Types->INT),   '... no more INT');
ok(!$ch->has(VM::Types->CHAR),  '... no more CHAR');
ok($ch->has(VM::Types->FLOAT), '... has FLOAT');

for (
    my $float = $ch->get(VM::Types->FLOAT);
    !($float isa VM::Value::NULL);
    $float = $ch->get(VM::Types->FLOAT)
) {
    isa_ok($float, 'VM::Value::FLOAT');
    say $float if DEBUG;
    say join ', ' => $ch->buffer if DEBUG;
}

ok(!$ch->has(VM::Types->INT),   '... no more INT');
ok(!$ch->has(VM::Types->CHAR),  '... no more CHAR');
ok(!$ch->has(VM::Types->FLOAT), '... no more FLOAT');

done_testing;













