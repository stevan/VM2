#!perl

use v5.40;
use experimental qw[ class ];

use Sub::Util ();

use VM::Internal::Tools;

use VM::Value::INT;
use VM::Value::FLOAT;
use VM::Value::CHAR;
use VM::Value::TRUE;
use VM::Value::FALSE;
use VM::Value::POINTER;

class VM::Opcodes {
    use constant ();

    our @OPCODES;
    BEGIN {
        @OPCODES = qw[
            CONST_INT
            CONST_TRUE
            CONST_FALSE

            ADD_INT

            JUMP
            JUMP_IF_FALSE

            PRINT

            HALT
        ];
        foreach my $i ( 0 .. $#OPCODES ) {
            no strict 'refs';
            my $op   = $OPCODES[$i];
            my $enum = enum $i++, $op;
            constant->import( $op => $enum );
        }
    }

    our @MICROCODE;
    BEGIN {
        $MICROCODE[HALT] = Sub::Util::set_subname( HALT => sub ($cpu) { $cpu->halt } );

        $MICROCODE[CONST_INT] = Sub::Util::set_subname( CONST_INT => sub ($cpu) {
            my $int = $cpu->next_op;
            $cpu->push( $int );
        });

        $MICROCODE[CONST_TRUE] = Sub::Util::set_subname( CONST_TRUE => sub ($cpu) {
            $cpu->push( VM::Value::TRUE->new );
        });

        $MICROCODE[CONST_FALSE] = Sub::Util::set_subname( CONST_FALSE => sub ($cpu) {
            $cpu->push( VM::Value::FALSE->new );
        });

        $MICROCODE[ADD_INT] = Sub::Util::set_subname( ADD_INT => sub ($cpu) {
            my $rhs = $cpu->pop;
            my $lhs = $cpu->pop;
            $cpu->push( VM::Value::INT->new( value => $lhs->value + $rhs->value ) );
        });

        $MICROCODE[JUMP] = Sub::Util::set_subname( JUMP => sub ($cpu) {
            my $addr = $cpu->next_op;
            $cpu->jump_to( $addr );
        });

        $MICROCODE[JUMP_IF_FALSE] = Sub::Util::set_subname( JUMP_IF_FALSE => sub ($cpu) {
            my $addr = $cpu->next_op;
            my $bool = $cpu->pop;
            if ( $bool isa VM::Value::FALSE ) {
                $cpu->jump_to( $addr );
            }
        });

        $MICROCODE[PRINT] = Sub::Util::set_subname( PRINT => sub ($cpu) {
            my $arg = $cpu->pop;
            #print $arg->to_string;
        });

        (scalar @MICROCODE == scalar @OPCODES)
            || die 'There must be microcode for each opcode, missing '
                   .(scalar @OPCODES - scalar @MICROCODE).' opcodes';
    }
}
