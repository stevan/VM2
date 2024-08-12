#!perl

use v5.40;
use experimental qw[ class ];

use List::Util;

use VM::Errors;

use VM::Memory::Pointer;

class VM::Memory::Block {
    field $capacity :param :reader;

    field @words;
    field $next_addr = 0;

    field @freed;

    method available { $capacity - $next_addr }

    method alloc ($size, $stride) {

        my $addr      = $next_addr;
        my $allocated = $size * $stride;

        #warn "addr: $addr allocated: $allocated capacity: $capacity needed: ".($next_addr + $allocated);
        die VM::Errors->OUT_OF_MEMORY if ($next_addr + $allocated) > $capacity;
        $next_addr += $allocated;

        my $pointer = VM::Memory::Pointer->new(
            address => $addr,
            stride  => $stride,
            size    => $allocated,
        );

        $words[ $_ ] = 0E0 foreach $pointer->address_range;

        return $pointer;
    }

    method is_freed ($p) { List::Util::first { refaddr $p == refaddr $_ } @freed }

    method free ($pointer) {
        die VM::Errors->POINTER_ALREADY_FREED if $self->is_freed( $pointer );
        $words[ $_ ] = undef foreach $pointer->address_range;
        push @freed => $pointer;
    }

    method resolve :lvalue ($pointer) {
        die VM::Errors->INVALID_POINTER if $self->is_freed( $pointer );

        my $address = $pointer->address;

        die VM::Errors->MEMORY_OVERFLOW  if $address > ($capacity - 1);
        die VM::Errors->MEMORY_UNDERFLOW if $address < 0;

        $words[ $address ];
    }

    method dump { \@words }

}
