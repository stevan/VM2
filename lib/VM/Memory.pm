#!perl

use v5.40;
use experimental qw[ class ];

use VM::Memory::Block;

class VM::Memory {
    field @blocks;

    method allocate_block ($capcity) {
        VM::Memory::Block->new( capacity => $capcity )
    }
}

