#!perl

use v5.40;
use experimental qw[ class ];

use importer 'Sub::Util' => qw[ set_subname ];

use VM::Internal::Tools;

class VM::Interrupts {
    class VM::Interrupts::Interrupt :isa(VM::Internal::Tools::Enum) {}

    use constant TIMER => VM::Interrupts::Interrupt->new( int => 1, label => 'TIMER' );
    use constant IO    => VM::Interrupts::Interrupt->new( int => 2, label => 'IO'    );
    use constant DEBUG => VM::Interrupts::Interrupt->new( int => 3, label => 'DEBUG' );

    # ...

    field $vm :param :reader;

    our @ISRS;
    method interrupt_table {
        my @isrs = @ISRS;

        my $_vm = $vm;

        $isrs[DEBUG] = set_subname( 'DEBUG_ISR' => sub ($cpu) {
            state $debugger = VM::Debugger->new( vm => $_vm );
            $debugger->call;
        });

        return \@isrs;
    }

    # ...

    BEGIN {
        $ISRS[TIMER] = set_subname( 'TIMER_ISR' => sub ($cpu) {});
        $ISRS[IO]    = set_subname( 'IO_ISR'    => sub ($cpu) {});
    }
}

