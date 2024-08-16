#!perl

use v5.40;
use experimental qw[ class ];

use importer 'List::Util' => qw[ first ];

use VM::Value::NULL;

class VM::Channel {
    field @buffer :reader;

    method is_empty { scalar @buffer == 0 }

    method flush { my @b = @buffer; @buffer = (); @b }

    method put ($v) { push @buffer => $v }

    method has ($type) {
        !!( first { $_->type->to_int == $type->to_int } @buffer )
    }

    method get ($type) {
        state $NULL = VM::Value::NULL->new;

        return $NULL unless @buffer;

        my $result;
        @buffer = grep {
            defined($result)
                ? true
                : $_->type->to_int == $type->to_int
                    ? (($result //= $_) && false)
                    : true
        } @buffer;

        return $result // $NULL;
    }
}
