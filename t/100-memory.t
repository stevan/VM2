#!perl

use v5.40;
use experimental qw[ class builtin ];

use Scalar::Util ();
use Sub::Util    ();

sub enum ($i, $s) { Scalar::Util::dualvar($i, $s) }

## ----------------------------------------------------------------------------

class VM::Mem::Pointer {

}
