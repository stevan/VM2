#!perl

use v5.40;
use experimental qw[ class ];

use VM::Types;

class VM::Value::CHAR :isa(VM::Value) {
    field $value :param :reader;
    method type { VM::Types->CHAR }
}
