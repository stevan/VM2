#!perl

use v5.40;
use experimental qw[ class ];

use VM::Debugger::Stack;
use VM::Debugger::Memory;

class VM::Debugger {
    field $vm :param :reader;


}
