#!perl

use v5.40;
use experimental qw[ class ];

class VM::Assembler {

    method assemble (@source) {
        #die join "\n" => map { blessed $_ ? $_->to_string : $_ } @source;

        # build the table of labels ...
        my %labels;
        my $label_idx = 0;
        foreach my $token (@source) {
            if ( blessed $token && $token isa VM::Assembler::Label && !$token->is_anchor ) {
                $labels{ $token->name } = $label_idx;
            } else {
                $label_idx++;
            }
        }

        #use Data::Dumper;
        #warn Dumper \%labels;

        # replace all the anchors with the label
        foreach my ($i, $token) (indexed @source) {
            if ( blessed $token && $token isa VM::Assembler::Label && $token->is_anchor ) {
                $source[$i] = $labels{ $token->name };
            }
        }

        my @code;
        foreach my $token (@source) {
            unless (blessed $token && $token isa VM::Assembler::Label) {
                push @code => $token;
            }
        }

        #die join "\n" => map { blessed $_ ? $_->to_string : $_ } @code;

       return \@code;
    }

}
