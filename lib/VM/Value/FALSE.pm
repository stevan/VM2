#!perl

use v5.40;
use experimental qw[ class ];

use VM::Types;

class VM::Value::FALSE :isa(VM::Value) {
    method value { false }
    method type  { VM::Types->BOOL }
    method to_string { '#f' }
}
