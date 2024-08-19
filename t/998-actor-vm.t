#!perl

use v5.40;
use experimental qw[ class builtin ];
use builtin      qw[ created_as_string created_as_number ];

use importer 'Scalar::Util' => qw[ dualvar ];
use constant ();

class Inst {
    our @OPS;
    BEGIN {
        my $x = 0;
        @OPS = map {
            constant->import( $_ => dualvar($x++, "$_") )
        } qw[
            PUSH
            POP
            DUP
            SWAP

            INC_INT
            DEC_INT

            EQ_INT
            LT_INT
            GT_INT

            PUT

            JUMP
            JUMP_IF_TRUE
            JUMP_IF_FALSE

            CREATE_MSG
            MSG_TO
            MSG_FROM
            MSG_BODY

            LOAD
            STORE

            SPAWN
            SELF
            NEXT
            SEND
            RECV

            YIELD
            STOP
        ]
    }
}

class Assembler {
    field $code          :reader;
    field $label_to_addr :reader;
    field $addr_to_label :reader;

    method assemble ($source) {
        my @source = @$source;

        # build the table of labels ...
        my %label_to_addr;
        my %addr_to_label;

        my $label_addr = 0;
        foreach my $token (@source) {
            if ( created_as_string($token) && $token =~ /^\.(.*)/ ) {
                my $label = $1;
                $label_to_addr{ $label      } = $label_addr;
                $addr_to_label{ $label_addr } = $label;
            } else {
                $label_addr++;
            }
        }

        # replace all the anchors with the label
        foreach my ($i, $token) (indexed @source) {
            if ( created_as_string($token) && $token =~ /^#(.*)/ ) {
                my $label = $1;
                $source[$i] = $label_to_addr{ $label };
            }
        }

        my @code;
        foreach my $token (@source) {
            unless ( created_as_string($token) && $token =~ /^(\#|\.)(.*)/ ) {
                push @code => $token;
            }
        }


        $code          = \@code;
        $label_to_addr = \%label_to_addr;
        $addr_to_label = \%addr_to_label;

        return;
    }
}

class Port {
    field @buffer :reader;

    method is_empty     { scalar @buffer == 0 }
    method is_not_empty { scalar @buffer != 0 }

    method flush { my @b = @buffer; @buffer = (); @b }

    method put ($v) { push @buffer => $v }

    method get {
        return unless @buffer;
        return shift @buffer
    }
}

class Message {
    use overload '""' => \&to_string;

    field $to   :param :reader;
    field $from :param :reader;
    field $body :param :reader;

    method to_string { sprintf 'msg<to:%s from:%s body:[%s]>', $to, $from // '~', $body // '~' }
}

class Process {
    use overload '""' => \&to_string;

    use constant READY   => 1; # waiting to do work ...
    use constant YIELDED => 2; # it has yielded control to the system
    use constant STOPPED => 3; # stopped entirely

    my @STATUS_NAME = qw[ READY YIELDED STOPPED ];

    my $PID_SEQ = 0;

    field $entry  :param :reader;  # start address of process
    field $name   :param :reader;  # name of the process (aka - entry label)

    field $pid    :reader;
    field $status :reader;         # one of the constants above
    field @stack  :reader;         # seperate stack
    field $sp     :reader = -1;

    field $sid :reader;
    field $sod :reader;

    ADJUST {
        $status = READY;

        $sid = Port->new;
        $sod = Port->new;

        $pid = ++$PID_SEQ;
    }

    method set_entry ($e) { $entry = $e }

    method push  ($v) { push @stack => $v }
    method pop        { pop @stack        }
    method peek       { $stack[-1]        }

    method get_stack_at ($i)     { $stack[$i]      }
    method set_stack_at ($i, $v) { $stack[$i] = $v }

    method ready { $status = READY   }
    method yield { $status = YIELDED }
    method stop  { $status = STOPPED }

    method is_ready   { $status == READY   }
    method is_yielded { $status == YIELDED }
    method is_stopped { $status == STOPPED }

    method to_string { sprintf '[%02d]<%s:%03d>' => $pid, $name, $entry }

    method dump {
        sprintf 'status: %s, entry: %03d, label: %s', $STATUS_NAME[$status-1], $entry, $name;
    }
}

class Monitor {
    method start ($vm, $p) {
        say "╭────────────────────────────────────────╮";
        say "│ ".(sprintf '%-38s' => $p->to_string)." │";
        say "╰─────┬────────────────────────┬─────────╯";
        say "  ic  │  pc #        curr inst │ [stack]";
        say "──────┼────────────────────────┼──────────"
    }

    method enter ($vm, $p) {
        printf "\e[0;41m %04d │ %03d > \e[0m %15s │ [%s]\n" => $vm->ic, $vm->pc, $vm->ci, join ', ' => $p->stack;
    }

    method out ($vm, $p, $x) {
        printf "\e[0;46m            %% \e[0m %s\n", $x;
    }

    method exit ($vm, $p) {
        printf "\e[0;42m %04d │ %03d < \e[0m %15s │ [%s]\n" => $vm->ic, $vm->pc, $vm->ci, join ', ' => $p->stack;
    }

    method end ($vm, $p) {}
}

class VM {
    use constant DEBUG => $ENV{DEBUG} // 0;

    field $monitor :param :reader = undef;

    field @code;
    field @procs;
    field @bus;

    field $ic :reader = 0;
    field $pc :reader = 0;
    field $ci :reader = undef;

    field $assembler;

    method assemble ($entry_label, $source) {
        $assembler = Assembler->new;
        $assembler->assemble($source);

        $self->load_code(
            $assembler->label_to_addr->{$entry_label},
            $assembler->code,
        );

        $self;
    }

    method spawn_new_process ($entry) {
        return Process->new(
            entry => $entry,
            name  => $assembler->addr_to_label->{$entry}
        )
    }

    method load_code ($entry, $code) {
        @code  = @$code;
        @procs = $self->spawn_new_process( $entry );
        $ic    = 0;
        $pc    = $entry;
        $ci    = undef;
        $self;
    }

    method next_op { $code[$pc++] }

    method run {
        push @bus => Message->new(
            to   => $procs[0],
            from => undef,
            body => undef,
        );

        while (@procs) {
            say "before running:\n    ".join "\n    " => map $_->dump, @procs;
            say "bus: ".join ', ' => @bus;
            my @p = @procs;

            while (@bus) {
                my $signal = shift @bus;
                my $to     = $signal->to;
                $to->sid->put( $signal );
                if ($to->is_yielded) {
                    $to->ready;
                }
            }

            foreach my $p (@p) {
                say "excuting process: ".$p->dump;
                $self->execute($p);
            }

            say "bus: ".join ', ' => @bus;
            say "after running:\n    ".join "\n    " => map $_->dump, @procs;
            @procs = grep !$_->is_stopped, @procs;
        }
    }

    method execute ($p) {
        $monitor->start($self, $p) if DEBUG;

        $pc = $p->entry;

        while (true) {
            my $op = $self->next_op;

            die "EOC" unless defined $op;

            $ic++;
            $ci = $op;

            $monitor->enter($self, $p) if DEBUG;

            # ----------------------------
            # stack ops
            # ----------------------------
            if ($op == Inst->PUSH) {
                my $v = $self->next_op;
                $p->push( $v );
            }
            elsif ($op == Inst->POP) {
                $p->pop;
            }
            elsif ($op == Inst->DUP) {
                $p->push( $p->peek );
            }
            elsif ($op == Inst->SWAP) {
                my $val1 = $p->pop;
                my $val2 = $p->pop;
                $p->push( $val1 );
                $p->push( $val2 );
            }
            elsif ($op == Inst->LOAD) {
                my $offset = $self->next_op;
                $p->push( $p->get_stack_at( $offset ) );
            }
            elsif ($op == Inst->STORE) {
                my $value  = $p->pop;
                my $offset = $self->next_op;
                $p->set_stack_at( $offset, $value );
            }
            # ----------------------------
            # math
            # ----------------------------
            elsif ($op == Inst->INC_INT) {
                $p->push( $p->pop + 1 );
            }
            elsif ($op == Inst->DEC_INT) {
                $p->push( $p->pop - 1 );
            }
            # ----------------------------
            # comparisons
            # ----------------------------
            elsif ($op == Inst->EQ_INT) {
                my $b = $p->pop;
                my $a = $p->pop;
                $p->push( $a == $b ? 1 : 0 );
            }
            elsif ($op == Inst->LT_INT) {
                my $b = $p->pop;
                my $a = $p->pop;
                $p->push( $a < $b ? 1 : 0 );
            }
            elsif ($op == Inst->GT_INT) {
                my $b = $p->pop;
                my $a = $p->pop;
                $p->push( $a > $b ? 1 : 0 );
            }
            # ----------------------------
            # i/0
            # ----------------------------
            elsif ($op == Inst->PUT) {
                my $x = $p->pop;
                if (DEBUG) {
                   $monitor->out($self, $p, $x)
                } else {
                    print $x;
                }
            }
            # ----------------------------
            # conditions
            # ----------------------------
            elsif ($op == Inst->JUMP) {
                $pc = $self->next_op;
            }
            elsif ($op == Inst->JUMP_IF_FALSE) {
                my $a = $self->next_op;
                my $x = $p->pop;
                $pc = $a unless $x;
            }
            elsif ($op == Inst->JUMP_IF_TRUE) {
                my $a = $self->next_op;
                my $x = $p->pop;
                $pc = $a if $x;
            }
            # ----------------------------
            # ...
            # ----------------------------
            elsif ($op == Inst->CREATE_MSG) {
                my $to   = $p->pop;
                my $body = $p->pop;
                $p->push(Message->new(
                    to   => $to,
                    from => $p,
                    body => $body,
                ));
            }
            elsif ($op == Inst->MSG_TO) {
                my $signal = $p->pop;
                $p->push($signal->to);
            }
            elsif ($op == Inst->MSG_FROM) {
                my $signal = $p->pop;
                $p->push($signal->from);
            }
            elsif ($op == Inst->MSG_BODY) {
                my $signal = $p->pop;
                $p->push($signal->body);
            }
            # ----------------------------
            # ...
            # ----------------------------
            elsif ($op == Inst->SPAWN) {
                my $entry = $self->next_op;
                my $proc  = $self->spawn_new_process( $entry );
                push @procs => $proc;
                $p->push( $proc );
            }
            elsif ($op == Inst->SELF) {
                $p->push( $p );
            }
            elsif ($op == Inst->SEND) {
                my $signal = $p->pop;
                push @bus => $signal;
            }
            elsif ($op == Inst->RECV) {
                if ($p->sid->is_not_empty) {
                    my $signal = $p->sid->get;
                    $p->push( $signal );
                } else {
                    $p->set_entry( $pc );
                    $p->yeild;
                }
            }
            elsif ($op == Inst->NEXT) {
                my $addr = $self->next_op;
                $p->set_entry( $addr );
            }
            elsif ($op == Inst->YIELD) {
                $p->yield;
            }
            elsif ($op == Inst->STOP) {
                $p->stop;
            }
            else {
                die "WTF IS THIS $op";
            }

            $monitor->exit($self, $p) if DEBUG;

            last unless $p->is_ready;
        }

        $monitor->end($self, $p) if DEBUG;
    }
}

my $vm = VM->new(
    monitor => Monitor->new,
)->assemble('main', [
    '.echo',
        Inst->RECV,

        Inst->MSG_BODY,
        Inst->DUP,

        Inst->PUT,

        Inst->DUP,
        Inst->PUSH, 0,
        Inst->EQ_INT,
        Inst->JUMP_IF_TRUE, '#echo.stop',

        Inst->DEC_INT,

        Inst->SELF,
        Inst->CREATE_MSG,
        Inst->SEND,

        Inst->NEXT, '#echo',
        Inst->YIELD,
    '.echo.stop',
        Inst->STOP,

    '.main',
        Inst->SPAWN, '#echo',
        Inst->SPAWN, '#echo',
        #Inst->DUP,

        Inst->PUSH, 10,
        Inst->SWAP,
        Inst->CREATE_MSG,
        Inst->SEND,

        Inst->PUSH, 5,
        Inst->SWAP,
        Inst->CREATE_MSG,
        Inst->SEND,

        Inst->STOP,
])->run;

__END__


    '.main',
        Inst->PUSH, 0,
    '.main.loop',
        Inst->INC_INT,
        Inst->DUP,
        Inst->DUP,
        Inst->PUT,
        Inst->PUSH, 5,
        Inst->GT_INT,
        Inst->JUMP_IF_FALSE, '#main.loop',

    Inst->STOP

my $code = q[
    ping:
        LOCAL i(0)      ; stash a local variable
    ping.loop:
        RECV            ; async block until receives message and pushes onto the stack          [] => [msg]
        DUP             ; duplicate this                                                        [msg] => [msg, msg]

        GET_MSG 0       ; message decomposition 0 = message sender pushed onto the stack        [msg,msg] => [msg,sender]
        SWAP            ;                                                                       [msg,msg] => [sender,msg]
        GET_MSG 1       ; message decomposition 1 = message body pushed onto the stack          [sender,msg] => [sender,int]
        INC_INT         ; increment the top of the stack by 1 and push the result on the stack  [sender,int] => [sender,int2]
        DUP             ;                                                                       [sender,int2] => [sender,int2,int2]
        STORE_LOCAL 0   ; store the incremented int in the local storage index = 0              [sender,int2,int2] => [sender,int2]

        SELF            ; put the self reference at the top of the stack                        [sender,int2] => [sender,int2,self]
        NEW_MSG         ; create a new message with whatever is on the top of the stack         [sender,int2,self] => [sender,msg2]
                        ; 0 = sender
                        ; 1 = body
        SWAP            ;                                                                       [sender,msg2] => [msg2,sender]
        SEND            ; send message with whatever is on the top of the stack                 [msg2,sender] => []
                        ; 0 = recipient
                        ; 1 = message
        NEXT #ping.loop ; leave the continuation address on the stack                           [cont]
        YIELD           ; yield control back to the system

    main:
        SPAWN #ping    ; spawn new #ping and push to the top of the stack       [] => [#ping1]
        SPAWN #ping    ; spawn new #ping and push to the top of the stack       [#ping1] => [#ping1,#ping2]

        PUSH i(0)      ;                                                        [#ping1,#ping2] => [#ping1,#ping2,int]
        NEW_MSG        ; 0 = #ping2, 1 = i(0)                                   [[#ping1,#ping2,int] => [#ping1,msg]
        SWAP           ;                                                        [#ping1,msg] => [msg,#ping1]
        SEND           ;                                                        [msg,#ping1] => []

        YIELD          ; yield and let the processes start to flow ...

];
