#!perl

use v5.40;
use experimental qw[ class builtin ];
use builtin      qw[ export_lexically ];

use importer 'Sub::Util' => qw[ set_subname ];

use VM::Opcodes;

use VM::Assembler::Label;

use VM::Value::INT;
use VM::Value::FLOAT;
use VM::Value::CHAR;
use VM::Value::TRUE;
use VM::Value::FALSE;
use VM::Value::POINTER;

package VM::Assembler::Assembly {
    sub import ($,@) {
        my %exports = (
            '&i' => \&i,
            '&f' => \&f,
            '&c' => \&c,

            '&label' => \&label,
        );

        foreach my $opcode ( VM::Opcodes->ALL_OPCODES->@* ) {
            my $code = VM::Opcodes->$opcode;
            $exports{ sprintf '&%s' => $opcode } = set_subname( $opcode, sub () { $code } );
        }

        export_lexically( %exports );
    }

    sub i ($i) { VM::Value::INT   ->new( value => $i ) }
    sub f ($f) { VM::Value::FLOAT ->new( value => $f ) }
    sub c ($c) { VM::Value::CHAR  ->new( value => $c ) }

    sub label ($l) { VM::Assembler::Label->new( label => $l ) }
}
