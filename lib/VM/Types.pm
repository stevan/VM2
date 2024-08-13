#!perl

use v5.40;
use experimental qw[ class builtin ];

use VM::Internal::Tools;

class VM::Types {
    class VM::Types::Type :isa(VM::Internal::Tools::Enum) {}

    use constant INT     => VM::Types::Type->new( int => 1, label => 'INT' );
    use constant FLOAT   => VM::Types::Type->new( int => 2, label => 'FLOAT' );
    use constant CHAR    => VM::Types::Type->new( int => 3, label => 'CHAR' );
    use constant BOOL    => VM::Types::Type->new( int => 4, label => 'BOOL' );
    use constant POINTER => VM::Types::Type->new( int => 5, label => 'POINTER' );
}
