#!perl

use v5.40;
use experimental qw[ class ];

use VM::Errors;

class VM::Memory::Pointer {
    use overload '""' => 'to_string';

    field $address :param;             # index into block
    field $size    :param :reader;     # size of allocated area
    field $stride  :param :reader;     # size of individual type
    field $offset         :reader = 0; # offset of the base address

    method base_address  { $address }
    method last_address  { ($address + ($size - 1)) }
    method address_range { $address .. $self->last_address }

    method length { $size / $stride }

    method address { $address + ($offset * $stride) }

    method inc {
        throw VM::Errors->POINTER_OVERFLOW  if (($offset + 1) * $stride) > $size;
        $offset++;
        $self;
    }

    method dec {
        throw VM::Errors->POINTER_UNDERFLOW if $offset <= 0;
        $offset--;
        $self;
    }

    method reset {
        $offset = 0;
        $self;
    }

    method index ($idx) {
        throw VM::Errors->POINTER_OVERFLOW  if ($idx * $stride) > ($size - 1);
        $offset = $idx;
        $self;
    }

    method to_string { sprintf '*<%04d:%d>[%d]' => $address, $size, $offset }
}
