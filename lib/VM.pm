#!perl

use v5.40;
use experimental qw[ class ];

use VM::Core;
use VM::Memory;
use VM::Channel;

use VM::Assembler;

class VM {
    use constant DEBUG => $ENV{DEBUG} // 0;

    use Term::ReadKey;

    field $heap_size :param :reader = 100;

    field $assembler :reader;
    field $core      :reader;
    field $memory    :reader;

    field $output_channel :reader;
    field $input_channel  :reader;

    ADJUST {
        $output_channel = VM::Channel->new;
        $input_channel  = VM::Channel->new;

        $assembler = VM::Assembler->new;
        $memory    = VM::Memory->new;
        $core      = VM::Core->new(
            heap           => $memory->allocate_block( $heap_size ),
            output_channel => $output_channel,
            input_channel  => $input_channel
        );
    }

    method heap { $core->heap }

    method assemble (@source) {
        $assembler->assemble(\@source);

        $core->load_code(
            $assembler->label_to_addr->{'main'},
            $assembler->code
        );
    }

    method execute ($debugger=undef) {
        while (true) {
            try {
                $core->execute( DEBUG ? $debugger : () );
            } catch ($e) {
                warn $e;
            }

            last if $core->halted;

            if (!$core->running) {
                warn "Waiting???";
                my $fh = *STDIN;
                ReadMode cbreak  => $fh;
                my $key = ReadKey 0, $fh;
                #warn "Got Key($key)";
                ReadMode restore => $fh;
                #warn "Restored!!!";
                $input_channel->put(VM::Value::CHAR->new( value => $key ));
                warn "Added c($key) to the channel ...";
                $core->interrupt;
                #warn "Interrupted!!!";
            }
        }
    }
}
