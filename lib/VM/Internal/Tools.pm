#!perl

use v5.40;
use experimental qw[ class builtin ];
use builtin      qw[ export_lexically ];

use Scalar::Util ();

package VM::Internal::Tools {
    sub import {
        export_lexically(
            '&enum' => \&enum
        )
    }

    sub enum ($i, $s) { Scalar::Util::dualvar($i, $s) }
}
