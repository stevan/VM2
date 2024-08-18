#!perl

use v5.40;
use experimental qw[ class ];

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

            EQ_INT
            LT_INT
            GT_INT

            PUT

            JUMP
            JUMP_IF_TRUE
            JUMP_IF_FALSE

            YIELD
            STOP
        ]
    }
}

class Process {
    use constant BLOCKED => 1; # blocked on a valye from RECV
    use constant YIELDED => 2; # it has yielded control to the system
    use constant STOPPED => 3; # stopped entirely

    field $entry  :param :reader;  # start address of process
    field $status :reader;         # one of the constants above
    field @stack  :reader;         # seperate stack
    field $sp     :reader = -1;

    ADJUST {
        $status = YIELDED;
    }

    method push ($v) { push @stack => $v }
    method pop       { pop @stack        }
    method peek      { $stack[-1]        }

    method yield { $status = YIELDED }
    method block { $status = BLOCKED }
    method stop  { $status = STOPPED }

    method is_yielded { $status == YIELDED }
    method is_blocked { $status == BLOCKED }
    method is_stopped { $status == STOPPED }
}

class VM {
    use constant DEBUG => $ENV{DEBUG} // 0;

    field @code;
    field @procs;

    field $pc = 0;

    method load_code ($entry, $code) {
        @code  = @$code;
        @procs = Process->new( entry => $entry );
        $self
    }

    method next_op { $code[$pc++] }

    method run {
        while (@procs) {
            foreach my $p (@procs) {
                if ($p->is_yielded) {
                    $self->execute($p);
                }
            }

            @procs = grep !$_->is_stopped, @procs;
        }

    }

    method execute ($p) {
        while (true) {
            my $op = $self->next_op;

            if (DEBUG) {
                printf "> %15s : %03d : [%s]\n" => $op, $pc, join ', ' => $p->stack;
            }

            die "EOC" unless defined $op;

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
                $p->push( $p->pop );
            }
            # ----------------------------
            # math
            # ----------------------------
            elsif ($op == Inst->INC_INT) {
                $p->push( $p->pop + 1 );
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
                printf "%% %s\n", $x;
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
            elsif ($op == Inst->YIELD) {
                $p->yield;
                last;
            }
            elsif ($op == Inst->STOP) {
                $p->stop;
                last;
            }
            else {
                die "WTF IS THIS $op";
            }

            if (DEBUG) {
                printf "< %15s : %03d : [%s]\n" => $op, $pc, join ', ' => $p->stack;
            }
        }
    }
}

my $vm = VM->new->load_code(0, [
    Inst->PUSH, 0,
    Inst->INC_INT,
    Inst->DUP,
    Inst->DUP,
    Inst->PUT,
    Inst->PUSH, 5,
    Inst->GT_INT,
    Inst->JUMP_IF_FALSE, 2,

    Inst->STOP
])->run;

__END__



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
