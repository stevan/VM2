#!perl

use v5.40;
use experimental qw[ class ];

class VM::Debugger::Code {
    field $vm     :param :reader;
    field $width  :param :reader = 50;
    field $height :param :reader = 20;

    field $count_fmt;
    field $value_fmt;

    field $active_fmt;
    field $inactive_fmt;
    field $label_fmt;

    ADJUST {
        $count_fmt = " %05d";
        $value_fmt = "%".($width - 8)."s"; # 5 for the counter, 2 for the divider

        $active_fmt   = "\e[0;33m\e[7m${count_fmt} ▶${value_fmt}\e[0m";
        $inactive_fmt = "${count_fmt} ┊${value_fmt}\e[0m";
        $label_fmt    = "\e[0;96m\e[4m\e[1m%-${width}s\e[0m";
    }

    method draw {
        my $asm = $vm->assembler;
        my $cpu = $vm->core;
        my $ci  = $cpu->ci;

        my @code      = $asm->code->@*;
        my %label_at = $asm->addr_to_label->%*;

        my sub handle_prev_op ($op, $acc) {
            my ($fmt, $op_color, $oper_color, $reset);
            if ($cpu->ci == $op->[0]) {
                $fmt        = $active_fmt;
                $op_color   = "";
                $oper_color = "";
                $reset      = "";
            } else {
                $fmt        = $inactive_fmt;
                $op_color   = "\e[0;32m";
                $oper_color = "\e[0;34m";
                $reset      = "\e[0m";
            }

            my @operands = map {
                $_ isa VM::Opcodes::Address
                    ? $label_at{ $_->address }
                    : $_
            } @$acc;

            @$acc = ();

            my @out;
            if (exists $label_at{ $op->[0] }) {
                push @out => sprintf $label_fmt => $label_at{ $op->[0] };
            }

            push @out => sprintf $fmt, $op->[0],
                         sprintf " ${op_color}%-s${oper_color}%".(($width - 10) - length $op->[1]->label)."s${reset} ",
                         $op->[1],
                         join ', ' => @operands;

            return @out;
        }

        my @out;
        my @acc;
        my $prev_op;
        foreach my ($i, $code) (indexed @code) {
            if ($code isa VM::Opcodes::Opcode) {
                if ($prev_op) {
                    push @out => handle_prev_op($prev_op, \@acc);
                }
                $prev_op = [ $i, $code ];
            } else {
                push @acc => $code;
            }
        }

        if ($prev_op) {
            push @out => handle_prev_op($prev_op, \@acc);
        }

        return @out;
    }

}
