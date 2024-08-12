#!perl

use v5.40;
use experimental qw[ class ];

class VM::Value {
    use overload '""' => 'to_string';
    method type;
    method value;
    method to_string { sprintf '%.1s(%s)' => lc $self->type, $self->value }
}
