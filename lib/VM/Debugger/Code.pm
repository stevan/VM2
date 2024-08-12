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
        $count_fmt = "%05d";
        $value_fmt = "%".($width - 7)."s"; # 5 for the counter, 2 for the divider

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

        my @out;
        foreach my ($i, $code) (indexed @code) {
            if (exists $label_at{ $i }) {
                push @out => sprintf $label_fmt => $label_at{ $i };
            }

            my $fmt;
            if ($ci == $i) {
                $fmt = $active_fmt;
            } else {
                $fmt = $inactive_fmt;
            }

            if ($code isa VM::Opcodes::Address) {
                push @out => sprintf $fmt, $i, $label_at{ $code->address };
            } else {
                push @out => sprintf $fmt, $i, $code;
            }
        }

        return @out;
    }

}
