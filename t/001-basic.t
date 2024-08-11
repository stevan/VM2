#!perl

use v5.40;
use experimental qw[ class builtin ];

use Scalar::Util ();
use Sub::Util    ();

sub enum ($i, $s) { Scalar::Util::dualvar($i, $s) }

## ----------------------------------------------------------------------------

class VM::Types {
    use constant INT     => ::enum 0x01, 'INT';
    use constant FLOAT   => ::enum 0x02, 'FLOAT';
    use constant CHAR    => ::enum 0x03, 'CHAR';
    use constant BOOL    => ::enum 0x04, 'BOOL';
    use constant POINTER => ::enum 0x05, 'POINTER';
}

class VM::Value {
    method type;
    method value;
    method to_string { sprintf '%.1s(%s)' => lc $self->type, $self->value }
}

class VM::Value::INT :isa(VM::Value) {
    field $value :param :reader;
    method type { VM::Types->INT }
}

## ----------------------------------------------------------------------------

class VM::Opcodes {
    use constant ();

    our @OPCODES;
    BEGIN {
        @OPCODES = qw[
            CONST_INT

            ADD_INT

            PRINT

            HALT
        ];
        foreach my $i ( 0 .. $#OPCODES ) {
            no strict 'refs';
            my $op   = $OPCODES[$i];
            my $enum = ::enum $i++, $op;
            constant->import( $op => $enum );
            $OPCODES[$i] = $enum;
        }
    }

    our @MICROCODE;
    BEGIN {
        $MICROCODE[HALT] = Sub::Util::set_subname( HALT => sub ($cpu) { $cpu->halt } );

        $MICROCODE[CONST_INT] = Sub::Util::set_subname( CONST_INT => sub ($cpu) {
            my $int = $cpu->next_op;
            $cpu->push( $int );
        });

        $MICROCODE[ADD_INT] = Sub::Util::set_subname( ADD_INT => sub ($cpu) {
            my $rhs = $cpu->pop;
            my $lhs = $cpu->pop;
            $cpu->push( VM::Value::INT->new( value => $lhs->value + $rhs->value ) );
        });

        $MICROCODE[PRINT] = Sub::Util::set_subname( PRINT => sub ($cpu) {
            my $arg = $cpu->pop;
            print $arg->to_string;
        });

        (scalar @MICROCODE == scalar @OPCODES)
            || die 'There must be microcode for each opcode, missing '
                   .(scalar @OPCODES - scalar @MICROCODE).' opcodes';
    }
}

class VM::Core {
    field @code;
    field @stack;

    field $ic =  0; # instruction counter (number of instructions run)
    field $pc =  0; # program counter (points to current instruction)
    field $ci =  0; # current instruction being run

    field $fp =  0; # frame pointer (points to the top of the current stack frame)
    field $sp = -1; # stack pointer (points to the current head of the stack)

    field $error   = undef;
    field $running = false;

    field @microcode;

    ADJUST {
        @microcode = @VM::Opcodes::MICROCODE;
    }

    method load_code ($code) {
        @code  = @$code;
        @stack = ();
        $ic    =  0;
        $pc    =  0;
        $ci    =  0;
        $fp    =  0;
        $sp    = -1;
        $error = undef;
    }

    method error :lvalue { $error }

    method push ($v) { $stack[++$sp] = $v }
    method pop       { $stack[$sp--]      }
    method peek      { $stack[$sp]        }

    method next_op { $code[$pc++] }

    method halt {
        $running = false;
        $sp      = -1;
        $fp      = 0;
    }

    method execute ($entry=0) {
        $pc      = $entry;
        $error   = undef;
        $running = true;

        while ($running && $pc < scalar @code) {
            $ci = $pc;
            my $opcode = $self->next_op;
            $microcode[$opcode]->($self);
            $ic++;
        }
    }
}

## ----------------------------------------------------------------------------

package VM::Assembly {
    use builtin qw[ export_lexically ];
    sub import ($,@) {
        my %exports = (
            '&i' => sub ($i) { VM::Value::INT->new( value => $i ) }
        );
        foreach my $opcode ( @VM::Opcodes::OPCODES ) {
            my $code = VM::Opcodes->$opcode;
            $exports{ sprintf '&%s' => $opcode } = sub () { $code };
        }

        export_lexically( %exports );
    }
}

package main;

BEGIN { VM::Assembly->import }

my $cpu = VM::Core->new;

$cpu->load_code([
    CONST_INT, i(1),
    CONST_INT, i(2),
    ADD_INT,
    PRINT,
    HALT
]);

$cpu->execute;














