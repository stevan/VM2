#!perl

use v5.40;
use experimental qw[ class builtin ];

use VM::Internal::Tools;

class VM::Types {
    use constant INT     => enum  1, 'INT';
    use constant FLOAT   => enum  2, 'FLOAT';
    use constant CHAR    => enum  3, 'CHAR';
    use constant BOOL    => enum  4, 'BOOL';
    use constant POINTER => enum  5, 'POINTER';
}
