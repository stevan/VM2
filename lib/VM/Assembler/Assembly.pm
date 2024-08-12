#!perl

use v5.40;
use experimental qw[ class builtin ];
use builtin      qw[ export_lexically ];

use VM::Opcodes;

use VM::Value::INT;
use VM::Value::FLOAT;
use VM::Value::CHAR;
use VM::Value::TRUE;
use VM::Value::FALSE;
use VM::Value::POINTER;

package VM::Assembler::Assembly {
    sub import ($,@) {
        my %exports = (
            '&i' => sub ($i) { VM::Value::INT   ->new( value => $i ) },
            '&f' => sub ($f) { VM::Value::FLOAT ->new( value => $f ) },
            '&c' => sub ($c) { VM::Value::CHAR  ->new( value => $c ) },
        );
        foreach my $opcode ( @VM::Opcodes::OPCODES ) {
            my $code = VM::Opcodes->$opcode;
            $exports{ sprintf '&%s' => $opcode } = sub () { $code };
        }

        export_lexically( %exports );
    }
}
