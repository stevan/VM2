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
    use overload '""' => 'to_string';
    method type;
    method value;
    method to_string { sprintf '%.1s(%s)' => lc $self->type, $self->value }
}

class VM::Value::INT :isa(VM::Value) {
    field $value :param :reader;
    method type { VM::Types->INT }
}

class VM::Value::FLOAT :isa(VM::Value) {
    field $value :param :reader;
    method type { VM::Types->FLOAT }
}

class VM::Value::CHAR :isa(VM::Value) {
    field $value :param :reader;
    method type { VM::Types->CHAR }
}

class VM::Value::TRUE :isa(VM::Value) {
    method value { true }
    method type  { VM::Types->BOOL }
    method to_string { '#t' }
}

class VM::Value::FALSE :isa(VM::Value) {
    method value { false }
    method type  { VM::Types->BOOL }
    method to_string { '#f' }
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
            #print $arg->to_string;
        });

        (scalar @MICROCODE == scalar @OPCODES)
            || die 'There must be microcode for each opcode, missing '
                   .(scalar @OPCODES - scalar @MICROCODE).' opcodes';
    }
}

## ----------------------------------------------------------------------------

class VM::Core {
    use constant DEBUG => $ENV{DEBUG} // 0;

    field @code  :reader;
    field @stack :reader;

    field $ic :reader =  0; # instruction counter (number of instructions run)
    field $pc :reader =  0; # program counter (points to current instruction)
    field $ci :reader =  0; # current instruction being run

    field $fp :reader =  0; # frame pointer (points to the top of the current stack frame)
    field $sp :reader = -1; # stack pointer (points to the current head of the stack)

    field $running :reader = false;
    field $error = undef;

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
        $self;
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

            if (DEBUG) {
                print "\e[2J\e[H\n";
                say join "\n" => Debugger::Stack->new( cpu => $self )->draw;
                my $x = <>;
            }
        }
    }
}

## ----------------------------------------------------------------------------

class Debugger::Stack {
    field $cpu    :param :reader;
    field $width  :param :reader = 30;
    field $height :param :reader = 20;

    field $count_fmt;
    field $title_fmt;
    field $value_fmt;
    field $sp_fmt;
    field $fp_fmt;
    field $fp_inner_fmt;
    field $above_sp_fmt;
    field $above_fp_fmt;
    field $active_fmt;

    my $double_arrow = '▶';
    my $single_arrow = '▷';
    my $divider_line = '┊';

    ADJUST {
        $count_fmt    = "%05d";
        $value_fmt    = "%${width}s";
        $sp_fmt       = "${count_fmt} %s\e[0;33m\e[4m\e[1m${value_fmt}\e[0m";
        $fp_fmt       = "${count_fmt} %s\e[0;32m\e[4m\e[1m${value_fmt}\e[0m";
        $fp_inner_fmt = "${count_fmt} %s\e[0;32m\e[2m\e[1m${value_fmt}\e[0m";
        $above_sp_fmt = "\e[38;5;240m${count_fmt} %s${value_fmt}\e[0m";
        $above_fp_fmt = "${count_fmt} %s\e[0;33m\e[1m${value_fmt}\e[0m";
        $active_fmt   = "${count_fmt} %s\e[0;36m${value_fmt}\e[0m";
    }

    method draw {
        my $fp    = $cpu->fp;
        my $sp    = $cpu->sp;
        my @stack = $cpu->stack;

        my $top    = $#stack;
        my $bottom = 0;

        if ($top > $height) {
            if ($sp > $height) {
                $bottom = $sp - $height;
                $top    = $sp;
            }
            else {
                $top = $height;
            }
        } elsif ($top < $height) {
            $top = $height;
        }

        my @display = $bottom .. $top;

        my @out;
        foreach my $i (reverse @display) {
            my $fmt;
            if ($i == $sp) {
                $fmt = $sp_fmt;
            } elsif ($i == $fp) {
                $fmt = $fp_fmt;
            } else {
                if ($i < $sp) {
                    if ($i > $fp) {
                        $fmt = $above_fp_fmt;
                    } elsif ($i > ($fp - 3)) {
                        $fmt = $fp_inner_fmt;
                    } else {
                        $fmt = $active_fmt;
                    }
                } else {
                    $fmt = $above_sp_fmt;
                }
            }

            my $div;
            if ($i == $fp && $i == $sp) {
                $div = $double_arrow;
            } elsif ($i == $fp) {
                $div = $single_arrow;
            } elsif ($i == $sp) {
                $div = $single_arrow;
            } else {
                $div = $divider_line;
            }

            push @out => sprintf $fmt => $i, $div, ($stack[$i] // '~');
        }
        return @out;
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

## ----------------------------------------------------------------------------

package main;

BEGIN { VM::Assembly->import }

my $cpu = VM::Core->new;

$cpu->load_code([
    (map { CONST_INT(), i($_) } ( 0 .. 25 )),
    (map { ADD_INT() } ( 0 .. 19 )),
    PRINT,
    HALT
]);

$cpu->execute;














