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

    method address_range { $address .. ($address + ($size - 1)) }

    method address {
        die VM::Errors->POINTER_OVERFLOW  if ($offset * $stride) > ($size - 1);
        die VM::Errors->POINTER_UNDERFLOW if $offset < 0;
        $address + ($offset * $stride)
    }

    method inc { $offset++ }
    method dec { $offset-- }

    method index ($idx) { $offset = $idx }

    method to_string { sprintf '*<%04d>[%d]' => $address, $offset }
}
