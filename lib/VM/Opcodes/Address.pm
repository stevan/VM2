#!perl

use v5.40;
use experimental qw[ class ];

class VM::Opcodes::Address {
    field $address :param :reader;
}
