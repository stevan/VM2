#!perl

use v5.40;
use experimental qw[ class ];

use VM::Types;

class VM::Value::INT :isa(VM::Value) {
    field $value :param :reader;
    method type { VM::Types->INT }
}
