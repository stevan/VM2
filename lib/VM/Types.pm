#!perl

use v5.40;
use experimental qw[ class builtin ];

use VM::Internal::Tools;

class VM::Types {
    use constant INT     => enum 0x01, 'INT';
    use constant FLOAT   => enum 0x02, 'FLOAT';
    use constant CHAR    => enum 0x03, 'CHAR';
    use constant BOOL    => enum 0x04, 'BOOL';
    use constant POINTER => enum 0x05, 'POINTER';
}
