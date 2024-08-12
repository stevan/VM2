#!perl

use v5.40;
use experimental qw[ class ];

use VM::Opcodes::Address;

class VM::Assembler {

    field @source        :reader;
    field $code          :reader;
    field $label_to_addr :reader;
    field $addr_to_label :reader;

    method assemble ($src) {
        @source = @$src;

        # build the table of labels ...
        my %label_to_addr;
        my %addr_to_label;

        my $label_addr = 0;
        foreach my $token (@source) {
            if ( blessed $token && $token isa VM::Assembler::Label && !$token->is_anchor ) {
                $label_to_addr{ $token->name } = $label_addr;
                $addr_to_label{ $label_addr  } = $token->name;
            } else {
                $label_addr++;
            }
        }

        # replace all the anchors with the label
        foreach my ($i, $token) (indexed @source) {
            if ( blessed $token && $token isa VM::Assembler::Label && $token->is_anchor ) {
                $source[$i] = VM::Opcodes::Address->new( address => $label_to_addr{ $token->name } );
            }
        }

        # remove the remaining labels from the code
        my @code;
        foreach my $token (@source) {
            unless (blessed $token && $token isa VM::Assembler::Label) {
                push @code => $token;
            }
        }

        $code          = \@code;
        $label_to_addr = \%label_to_addr;
        $addr_to_label = \%addr_to_label;

       return;
    }

}
