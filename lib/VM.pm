#!perl

use v5.40;
use experimental qw[ class ];

use importer 'Term::ReadKey' => qw[ ReadKey ReadMode ];

use VM::CPU;
use VM::Memory;
use VM::Clock;
use VM::Channel;
use VM::Interrupts;
use VM::Opcodes;

use VM::Assembler;
use VM::Debugger;

class VM {
    field $heap_size :param :reader = 100;

    field $assembler :reader;

    # CPU and RAM
    field $clock  :reader;
    field $cpu    :reader;
    field $memory :reader;
    # serial input/ouput device
    field $sod    :reader;
    field $sid    :reader;

    # internals ...
    field $opcodes    :reader;
    field $interrupts :reader;

    ADJUST {
        $sod    = VM::Channel->new;
        $sid    = VM::Channel->new;
        $memory = VM::Memory->new;
        $clock  = VM::Clock->new;
        $cpu    = VM::CPU->new(
            heap => $memory->allocate_block( $heap_size ),
            sod  => $sod,
            sid  => $sid,
        );

        $opcodes    = VM::Opcodes->new( vm => $self );
        $interrupts = VM::Interrupts->new( vm => $self );

        $cpu->load_microcode( $opcodes->microcode );
        $cpu->load_interrupt_table( $interrupts->interrupt_table );

        # create an assembler for later ...
        $assembler = VM::Assembler->new;
    }

    method heap { $cpu->heap }

    method assemble (@source) {
        $assembler->assemble(\@source);

        $cpu->load_code(
            $assembler->label_to_addr->{'main'},
            $assembler->code
        );
    }

    method execute {
        try {
            until ($cpu->completed) {
                $clock->tick( $cpu );

                if (!$sod->is_empty && !$interrupts->is_debugging) {
                    print join '' => map $_->value, $sod->flush;
                }

                if ($cpu->halted) {
                    warn "CPU halted ...";
                    ReadMode cbreak  => *STDIN;
                    my $x = ReadKey 0, *STDIN;
                    ReadMode restore => *STDIN;

                    $sid->put( VM::Value::CHAR->new( value => $x ) );
                    $cpu->irq = VM::Interrupts->IO;
                    $cpu->resume;
                }
            }

            if (!$sod->is_empty && !$interrupts->is_debugging) {
                print join '' => map $_->value, $sod->flush;
            }
        } catch ($e) {
            chomp $e;
            die "Unexpected Runtime Exception: $e";
        }
    }
}
