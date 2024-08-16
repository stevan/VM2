#!perl

use v5.40;
use experimental qw[ class ];

use VM::Types;

class VM::Value::CHAR :isa(VM::Value) {
    field $value :param :reader;
    method type { VM::Types->CHAR }
    method to_string {
        my $char = $self->value;
        # so newlines do not mess up any display
        $char = '\n' if $char eq "\n";
        sprintf '%.1s(%s)' => lc $self->type, $char
    }
}
