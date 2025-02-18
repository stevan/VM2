#!perl

use v5.40;
use experimental qw[ class ];

use importer 'List::Util' => qw[ first ];

use VM::Errors;

use VM::Value::NULL;
use VM::Memory::Pointer;

class VM::Memory::Block {
    field $capacity :param :reader;

    field @words :reader;

    field @allocated :reader;
    field @freed     :reader;

    field $next_addr = 0;

    my $NULL = VM::Value::NULL->new;

    method available { $capacity - $next_addr }

    method alloc ($size, $stride) {

        my $addr      = $next_addr;
        my $allocated = $size * $stride;

        #warn "addr: $addr allocated: $allocated capacity: $capacity needed: ".($next_addr + $allocated);

        if (($next_addr + $allocated) > $capacity) {
            # find one with the right size ...
            my $available = first { $_->size == $allocated } @freed;
            # otherwise we are out of memory
            throw VM::Errors->OUT_OF_MEMORY if not defined $available;
            # but if we did, just use that base address
            $addr = $available->base_address;
            # and now remove it from the freed list
            @freed = grep { refaddr $available != refaddr $_ } @freed;
        }
        else {
            $next_addr += $allocated;
        }

        my $pointer = VM::Memory::Pointer->new(
            address => $addr,
            stride  => $stride,
            size    => $allocated,
        );

        $words[ $_ ] = $NULL foreach $pointer->address_range;

        push @allocated => $pointer;

        return $pointer;
    }

    method is_freed ($p) { first { refaddr $p == refaddr $_ } @freed }

    method free ($pointer) {
        throw VM::Errors->POINTER_ALREADY_FREED if $self->is_freed( $pointer );

        @allocated = grep { refaddr $pointer != refaddr $_ } @allocated;
        $words[ $_ ] = undef foreach $pointer->address_range;
        push @freed => $pointer;

        $self->compact_block;
    }

    method compact_block {
        while ($next_addr > 0 && not defined $words[ $next_addr - 1 ]) {
            $next_addr--;
        }
    }

    method resolve :lvalue ($pointer) {
        throw VM::Errors->INVALID_POINTER if $self->is_freed( $pointer );

        my $address = $pointer->address;

        throw VM::Errors->MEMORY_OVERFLOW  if $address > ($capacity - 1);
        throw VM::Errors->MEMORY_UNDERFLOW if $address < 0;

        if ($pointer->stride == 1) {
            return $words[ $address ];
        } else {
            return VM::Memory::Pointer->new(
                address => $address,
                stride  => 1,
                size    => $pointer->stride,
            );
        }
    }
}
