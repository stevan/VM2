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

    field $is_debugging = false;

    method is_debugging :lvalue { $is_debugging }

    method interrupt_table {
        my @isrs;
        $isrs[DEBUG] = set_subname( 'DEBUG_ISR' => sub ($cpu) {
            state $debugger = VM::Debugger->new( vm => $self->vm );
            $debugger->call;

            if ($cpu->irq && $cpu->irq->to_int == VM::Interrupts->DEBUG->to_int) {
                $self->is_debugging = true;
            } else {
                $self->is_debugging = false;
            }
        });

        $isrs[IO] = set_subname( 'IO_ISR'    => sub ($cpu) {
            if ($is_debugging) {
                $cpu->irq = VM::Interrupts->DEBUG;
            }
        });

        $isrs[TIMER] = set_subname( 'TIMER_ISR' => sub ($cpu) {
            if ($is_debugging) {
                $cpu->irq = VM::Interrupts->DEBUG;
            }
        });

        return \@isrs;
    }

}

