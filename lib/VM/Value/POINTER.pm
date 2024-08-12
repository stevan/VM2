#!perl

use v5.40;
use experimental qw[ class ];

use VM::Types;

class VM::Value::POINTER :isa(VM::Value) {
    field $value :param :reader;

    method type { VM::Types->POINTER }

    method to_string { $value->to_string }
}
