#!perl

use v5.40;
use experimental qw[ class ];

class VM::Assembler::Label {
    use overload '""' => 'to_string';

    field $label :param :reader;

    method name      { ($label =~ /^[.#](.*)$/)[0] }
    method is_anchor { $label =~ /^#/ ? true : false }

    method to_string { $label }
}
