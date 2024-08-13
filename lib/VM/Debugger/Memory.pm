#!perl

use v5.40;
use experimental qw[ class ];

class VM::Debugger::Memory {
    field $block  :param :reader;
    field $width  :param :reader = 30;

    field $count_fmt;
    field $value_fmt;
    field $title_fmt;

    field %used_colors;

    ADJUST {
        $count_fmt = "%05d";
        $value_fmt = "%".($width - 7)."s"; # 5 for the counter, 2 for the divider
        $title_fmt = "%-${width}s";
    }

    method draw {
        my @words  = $block->words;
        my %freed  = map { refaddr $_, $_ } $block->freed;
        my @sorted = sort { $a->base_address <=> $b->base_address } ($block->allocated, $block->freed);

        my @out;

        push @out => (sprintf "\e[1m${title_fmt}\e[0m" => '══ Addresses '.('═' x ($width - 13)));

        if (@sorted) {
            foreach my $ptr (@sorted) {
                my $color = $used_colors{ refaddr $ptr } //= [ map { int(rand(10)) * 10 } qw[ r g b ] ];
                foreach my $address ( $ptr->address_range ) {
                    unless (exists $freed{ refaddr $ptr }) {
                        push @out => sprintf "\e[48;2;%d;%d;%d;m${count_fmt} ┊${value_fmt}\e[0m" => @$color, $address, $words[$address];
                    } else {
                        push @out => sprintf "\e[38;5;240m${count_fmt} ┊${value_fmt}\e[0m" => $address, '~';
                    }
                }

            }
        } else {
            push @out => (sprintf "\e[2m      ┊${value_fmt}\e[0m" => '~');
        }

        push @out => (sprintf "\e[1m${title_fmt}\e[0m" => '══ Pointers '.('═' x ($width - 12)));

        push @out => (sprintf "\e[4m${title_fmt}\e[0m" => 'allocated');
        if ($block->allocated) {
            foreach my ($i, $ptr) ( indexed $block->allocated ) {
                push @out => sprintf "\e[48;2;%d;%d;%d;m${count_fmt} ┊${value_fmt}\e[0m" => $used_colors{ refaddr $ptr }->@*, $i, $ptr->to_string
            }
        } else {
            push @out => (sprintf "\e[2m      ┊${value_fmt}\e[0m" => '~');
        }

        push @out => (sprintf "\e[4m${title_fmt}\e[0m" => 'freed');
        if ($block->freed) {
            foreach my ($i, $ptr) ( indexed $block->freed ) {
                push @out => sprintf "\e[38;5;240m${count_fmt} ┊${value_fmt}\e[0m" => $i, $ptr->to_string
            }
        } else {
            push @out => (sprintf "\e[2m      ┊${value_fmt}\e[0m" => '~');
        }

        return @out;
    }
}
