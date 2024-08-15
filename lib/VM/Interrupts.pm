#!perl

use v5.40;
use experimental qw[ class ];

use importer 'Sub::Util'   => qw[ set_subname ];
use importer 'Time::HiRes' => qw[ sleep ];

use VM::Internal::Tools;

class VM::Interrupts {
    class VM::Interrupts::Interrupt :isa(VM::Internal::Tools::Enum) {}

    use constant DEBUG => VM::Interrupts::Interrupt->new( int => 0, label => 'DEBUG' );
    use constant TIMER => VM::Interrupts::Interrupt->new( int => 1, label => 'TIMER' );
    use constant IO    => VM::Interrupts::Interrupt->new( int => 2, label => 'IO'    );

    our @ISRS;
    BEGIN {
        $ISRS[DEBUG] = set_subname( 'DEBUG_ISR' => sub ($cpu) {
            print "\e[2J\e[H\n";
            say join "\n" => $cpu->debugger->draw;
            if (my $sleep = $ENV{CLOCK}) {
                sleep($sleep);
            } else {
                my $x = <>;
            }

            $cpu->irq = VM::Interrupts->DEBUG;
        });

        $ISRS[TIMER] = set_subname( 'TIMER_ISR' => sub ($cpu) {});
        $ISRS[IO]    = set_subname( 'IO_ISR'    => sub ($cpu) {});
    }
}

