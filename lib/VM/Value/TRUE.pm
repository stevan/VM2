#!perl

use v5.40;
use experimental qw[ class ];

use VM::Types;

class VM::Value::TRUE :isa(VM::Value) {
    method value { true }
    method type  { VM::Types->BOOL }
    method to_string { '#t' }
}
