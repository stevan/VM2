#!perl

use v5.40;
use experimental qw[ class builtin ];
use builtin      qw[ export_lexically ];

use Scalar::Util ();
use constant     ();

class VM::Internal::Tools::Enum {
    use overload '""' => 'to_string',
                 '0+' => 'to_int';
    field $int :param :reader;
    field $label :param :reader;
    method to_string { $label }
    method to_int    { $int   }
}
