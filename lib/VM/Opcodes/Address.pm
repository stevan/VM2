#!perl

use v5.40;
use experimental qw[ class ];

class VM::Opcodes::Address {
    use overload '""' => 'to_string';

    field $address :param :reader;

    method to_string { sprintf '#%05d' => $address }
}
