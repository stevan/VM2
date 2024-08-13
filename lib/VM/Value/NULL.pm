#!perl

use v5.40;
use experimental qw[ class ];

use VM::Types;

class VM::Value::NULL :isa(VM::Value) {
    method value { undef }
    method type  { VM::Types->NULL }
    method to_string { '*n' }
}
