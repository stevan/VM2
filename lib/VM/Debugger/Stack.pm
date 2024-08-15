#!perl

use v5.40;
use experimental qw[ class ];

class VM::Debugger::Stack {
    field $vm     :param :reader;
    field $width  :param :reader = 30;
    field $height :param :reader = 20;

    field $count_fmt;
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
        $value_fmt    = "%".($width - 7)."s"; # 5 for the counter, 2 for the divider
        $sp_fmt       = "${count_fmt} %s\e[0;33m\e[4m\e[1m${value_fmt}\e[0m";
        $fp_fmt       = "${count_fmt} %s\e[0;32m\e[4m\e[1m${value_fmt}\e[0m";
        $fp_inner_fmt = "${count_fmt} %s\e[0;32m\e[2m\e[1m${value_fmt}\e[0m";
        $above_sp_fmt = "\e[38;5;240m${count_fmt} %s${value_fmt}\e[0m";
        $above_fp_fmt = "${count_fmt} %s\e[0;33m\e[1m${value_fmt}\e[0m";
        $active_fmt   = "${count_fmt} %s\e[0;36m${value_fmt}\e[0m";
    }

    method set_height ($h) { $height = $h }

    method draw {
        my $cpu   = $vm->cpu;
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
