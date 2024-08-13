#!perl

use v5.40;
use experimental qw[ class builtin ];

use VM::Internal::Tools;

class VM::Types {
    class VM::Types::Type :isa(VM::Internal::Tools::Enum) {
        field $size :reader :param;
    }

    use constant NULL    => VM::Types::Type->new( int => 0, size => 1, label => 'NULL' );
    use constant INT     => VM::Types::Type->new( int => 1, size => 1, label => 'INT' );
    use constant FLOAT   => VM::Types::Type->new( int => 2, size => 1, label => 'FLOAT' );
    use constant CHAR    => VM::Types::Type->new( int => 3, size => 1, label => 'CHAR' );
    use constant BOOL    => VM::Types::Type->new( int => 4, size => 1, label => 'BOOL' );
    use constant POINTER => VM::Types::Type->new( int => 5, size => 1, label => 'POINTER' );
}
