#!perl

use v5.40;
use experimental qw[ class ];

use importer 'Sub::Util' => qw[ set_subname ];

use VM::Internal::Tools;

use VM::Value::NULL;
use VM::Value::INT;
use VM::Value::FLOAT;
use VM::Value::CHAR;
use VM::Value::TRUE;
use VM::Value::FALSE;
use VM::Value::POINTER;

class VM::Opcodes {
    field $vm :param :reader;

    our @MICROCODE;
    method microcode { \@MICROCODE }

    class VM::Opcodes::Opcode :isa(VM::Internal::Tools::Enum) {}

    my @OPCODE_NAMES;
    BEGIN {
        @OPCODE_NAMES = qw[
            BREAKPOINT
            HALT
            EXIT

            CONST_NULL

            CONST_TRUE
            CONST_FALSE

            INC_INT
            DEC_INT

            INC_CHAR
            DEC_CHAR

            ADD_INT
            SUB_INT
            MUL_INT
            DIV_INT
            MOD_INT

            EQ_INT
            LT_INT
            GT_INT

            EQ_CHAR
            LT_CHAR
            GT_CHAR
            LE_CHAR
            GE_CHAR

            AND
            OR

            IS_NULL

            JUMP
            JUMP_IF_FALSE
            JUMP_IF_TRUE

            LOAD
            STORE

            ALLOC_MEM
            LOAD_MEM
            STORE_MEM
            FREE_MEM
            CLEAR_MEM
            COPY_MEM
            COPY_MEM_FROM

            LOAD_ARG
            CALL
            RETURN

            PUT
            GET_CHAR
            GET_INT
            GET_FLOAT

            DUP
            POP
            PUSH
            SWAP
        ];
        foreach my $i ( 0 .. $#OPCODE_NAMES ) {
            no strict 'refs';
            my $op   = $OPCODE_NAMES[$i];
            my $enum = VM::Opcodes::Opcode->new( int => $i++, label => $op );
            constant->import( $op => $enum );
        }

        constant->import( ALL_OPCODES => \@OPCODE_NAMES );
    }

    BEGIN {
        # build the microcode instructions ...

        ## ----------------------------------------------------------
        ## Interrupts
        ## ----------------------------------------------------------

        $MICROCODE[BREAKPOINT] = set_subname( BREAKPOINT => sub ($cpu) {
            $cpu->irq = VM::Interrupts->DEBUG;
        });

        ## ----------------------------------------------------------
        ## Constants
        ## ----------------------------------------------------------

        $MICROCODE[HALT] = set_subname( HALT => sub ($cpu) { $cpu->halt } );
        $MICROCODE[EXIT] = set_subname( HALT => sub ($cpu) { $cpu->exit });

        ## ----------------------------------------------------------
        ## Constants
        ## ----------------------------------------------------------

        $MICROCODE[CONST_NULL] = set_subname( CONST_NULL => sub ($cpu) {
            $cpu->push( VM::Value::NULL->new );
        });

        $MICROCODE[CONST_TRUE] = set_subname( CONST_TRUE => sub ($cpu) {
            $cpu->push( VM::Value::TRUE->new );
        });

        $MICROCODE[CONST_FALSE] = set_subname( CONST_FALSE => sub ($cpu) {
            $cpu->push( VM::Value::FALSE->new );
        });

        $MICROCODE[IS_NULL] = set_subname( IS_NULL => sub ($cpu) {
            my $value = $cpu->pop;
            $cpu->push( $value isa VM::Value::NULL ? VM::Value::TRUE->new : VM::Value::FALSE->new );
        });

        ## ----------------------------------------------------------
        ## Math
        ## ----------------------------------------------------------

        $MICROCODE[INC_INT] = set_subname( INC_INT => sub ($cpu) {
            my $lhs = $cpu->pop;
            $cpu->push( VM::Value::INT->new( value => $lhs->value + 1 ) );
        });

        $MICROCODE[DEC_INT] = set_subname( DEC_INT => sub ($cpu) {
            my $lhs = $cpu->pop;
            $cpu->push( VM::Value::INT->new( value => $lhs->value - 1 ) );
        });

        $MICROCODE[INC_CHAR] = set_subname( INC_CHAR => sub ($cpu) {
            my $lhs = $cpu->pop;
            my $char = ord($lhs->value);
            $cpu->push( VM::Value::CHAR->new( value => chr(++$char) ) );
        });

        $MICROCODE[DEC_CHAR] = set_subname( DEC_CHAR => sub ($cpu) {
            my $lhs = $cpu->pop;
            my $char = ord($lhs->value);
            $cpu->push( VM::Value::CHAR->new( value => chr(--$char) ) );
        });

        $MICROCODE[ADD_INT] = set_subname( ADD_INT => sub ($cpu) {
            my $rhs = $cpu->pop;
            my $lhs = $cpu->pop;
            $cpu->push( VM::Value::INT->new( value => $lhs->value + $rhs->value ) );
        });

        $MICROCODE[SUB_INT] = set_subname( SUB_INT => sub ($cpu) {
            my $rhs = $cpu->pop;
            my $lhs = $cpu->pop;
            $cpu->push( VM::Value::INT->new( value => $lhs->value - $rhs->value ) );
        });

        $MICROCODE[MUL_INT] = set_subname( MUL_INT => sub ($cpu) {
            my $rhs = $cpu->pop;
            my $lhs = $cpu->pop;
            $cpu->push( VM::Value::INT->new( value => $lhs->value * $rhs->value ) );
        });

        $MICROCODE[DIV_INT] = set_subname( DIV_INT => sub ($cpu) {
            my $rhs = $cpu->pop;
            my $lhs = $cpu->pop;
            if ( $rhs == 0 ) {
                return VM::Errors->ILLEGAL_DIVISION_BY_ZERO;
            }
            $cpu->push( VM::Value::INT->new( value => $lhs->value / $rhs->value ) );
        });

        $MICROCODE[MOD_INT] = set_subname( MOD_INT => sub ($cpu) {
            my $rhs = $cpu->pop;
            my $lhs = $cpu->pop;
            if ( $rhs == 0 ) {
                return VM::Errors->ILLEGAL_MOD_BY_ZERO;
            }
            $cpu->push( VM::Value::INT->new( value => $lhs->value % $rhs->value ) );
        });

        ## ----------------------------------------------------------
        ## Logic
        ## ----------------------------------------------------------

        $MICROCODE[EQ_INT] = set_subname( EQ_INT => sub ($cpu) {
            my $rhs = $cpu->pop;
            my $lhs = $cpu->pop;
            $cpu->push( $lhs->value == $rhs->value ? VM::Value::TRUE->new : VM::Value::FALSE->new );
        });

        $MICROCODE[LT_INT] = set_subname( LT_INT => sub ($cpu) {
            my $rhs = $cpu->pop;
            my $lhs = $cpu->pop;
            $cpu->push( $lhs->value < $rhs->value ? VM::Value::TRUE->new : VM::Value::FALSE->new );
        });

        $MICROCODE[GT_INT] = set_subname( GT_INT => sub ($cpu) {
            my $rhs = $cpu->pop;
            my $lhs = $cpu->pop;
            $cpu->push( $lhs->value > $rhs->value ? VM::Value::TRUE->new : VM::Value::FALSE->new );
        });


        $MICROCODE[EQ_CHAR] = set_subname( EQ_CHAR => sub ($cpu) {
            my $rhs = $cpu->pop;
            my $lhs = $cpu->pop;
            $cpu->push( $lhs->value eq $rhs->value ? VM::Value::TRUE->new : VM::Value::FALSE->new );
        });

        $MICROCODE[LT_CHAR] = set_subname( LT_CHAR => sub ($cpu) {
            my $rhs = $cpu->pop;
            my $lhs = $cpu->pop;
            $cpu->push( $lhs->value lt $rhs->value ? VM::Value::TRUE->new : VM::Value::FALSE->new );
        });

        $MICROCODE[GT_CHAR] = set_subname( GT_CHAR => sub ($cpu) {
            my $rhs = $cpu->pop;
            my $lhs = $cpu->pop;
            $cpu->push( $lhs->value gt $rhs->value ? VM::Value::TRUE->new : VM::Value::FALSE->new );
        });

        $MICROCODE[LE_CHAR] = set_subname( LTE_CHAR => sub ($cpu) {
            my $rhs = $cpu->pop;
            my $lhs = $cpu->pop;
            $cpu->push( $lhs->value le $rhs->value ? VM::Value::TRUE->new : VM::Value::FALSE->new );
        });

        $MICROCODE[GE_CHAR] = set_subname( GTE_CHAR => sub ($cpu) {
            my $rhs = $cpu->pop;
            my $lhs = $cpu->pop;
            $cpu->push( $lhs->value ge $rhs->value ? VM::Value::TRUE->new : VM::Value::FALSE->new );
        });

        ## ----------------------------------------------------------
        ## Logical
        ## ----------------------------------------------------------

        $MICROCODE[AND] = set_subname( AND => sub ($cpu) {
            my $rhs = $cpu->pop;
            my $lhs = $cpu->pop;
            $cpu->push( $lhs->value && $rhs->value ? VM::Value::TRUE->new : VM::Value::FALSE->new );
        });

        $MICROCODE[OR] = set_subname( OR => sub ($cpu) {
            my $rhs = $cpu->pop;
            my $lhs = $cpu->pop;
            $cpu->push( $lhs->value || $rhs->value ? VM::Value::TRUE->new : VM::Value::FALSE->new );
        });

        ## ----------------------------------------------------------
        ## Jumps
        ## ----------------------------------------------------------

        $MICROCODE[JUMP] = set_subname( JUMP => sub ($cpu) {
            my $addr = $cpu->next_op;
            $cpu->jump_to( $addr->address );
        });

        $MICROCODE[JUMP_IF_FALSE] = set_subname( JUMP_IF_FALSE => sub ($cpu) {
            my $addr = $cpu->next_op;
            my $bool = $cpu->pop;
            if ( $bool isa VM::Value::FALSE ) {
                $cpu->jump_to( $addr->address );
            }
        });

        $MICROCODE[JUMP_IF_TRUE] = set_subname( JUMP_IF_TRUE => sub ($cpu) {
            my $addr = $cpu->next_op;
            my $bool = $cpu->pop;
            if ( $bool isa VM::Value::TRUE ) {
                $cpu->jump_to( $addr->address );
            }
        });

        ## ----------------------------------------------------------
        ## subroutine calls
        ## ----------------------------------------------------------

        $MICROCODE[LOAD_ARG] = set_subname( LOAD_ARG => sub ($cpu) {
            my $offset = $cpu->next_op;
            $cpu->push( $cpu->stack_index(($cpu->fp - 3) - $offset) );
        });

        $MICROCODE[CALL] = set_subname( CALL => sub ($cpu) {
            my $addr = $cpu->next_op; # func address to go to
            my $argc = $cpu->next_op; # number of args the function has ...
            # stash the context ...
            $cpu->push($argc);
            $cpu->push($cpu->fp);
            $cpu->push($cpu->pc);
            # set the new context ...
            $cpu->move_fp( $cpu->sp );   # set the new frame pointer
            $cpu->jump_to( $addr->address ); # and the program counter to the func addr
        });

        $MICROCODE[RETURN] = set_subname( RETURN => sub ($cpu) {
            my $return_val = $cpu->pop; # pop the return value from the stack

            $cpu->move_sp( $cpu->fp  );         # restore stack pointer
            $cpu->jump_to( $cpu->pop );  # get the stashed program counter
            $cpu->move_fp( $cpu->pop );  # get the stashed program frame pointer

            my $argc = $cpu->pop;  # get the number of args
            $cpu->move_sp( $cpu->sp - $argc ); # decrement stack pointer by num args

            $cpu->push($return_val); # push the return value onto the stack
        });

        ## ----------------------------------------------------------
        ## Locals
        ## ----------------------------------------------------------

        $MICROCODE[LOAD] = set_subname( LOAD => sub ($cpu) {
            my $offset = $cpu->next_op;
            $cpu->push( $cpu->stack_index( $cpu->fp + $offset ) );
        });

        $MICROCODE[STORE] = set_subname( STORE => sub ($cpu) {
            my $value  = $cpu->pop;
            my $offset = $cpu->next_op;
            $cpu->stack_index( $cpu->fp + $offset ) = $value;
        });

        ## ----------------------------------------------------------
        ## Memory
        ## ----------------------------------------------------------

        $MICROCODE[ALLOC_MEM] = set_subname( ALLOC_MEM => sub ($cpu) {
            my $size   = $cpu->pop;
            my $stride = $cpu->next_op;

            my $ptr = $cpu->heap->alloc( $size->value, $stride );
            $cpu->push( VM::Value::POINTER->new( value => $ptr ) );
        });

        $MICROCODE[LOAD_MEM] = set_subname( LOAD_MEM => sub ($cpu) {
            my $ptr    = $cpu->pop;
            my $offset = $cpu->pop;

            $cpu->push( $cpu->heap->resolve( $ptr->value->index( $offset->value ) ) );
        });

        $MICROCODE[STORE_MEM] = set_subname( STORE_MEM => sub ($cpu) {
            my $ptr    = $cpu->pop;
            my $offset = $cpu->pop;
            my $value  = $cpu->pop;

            $cpu->heap->resolve( $ptr->value->index( $offset->value ) ) = $value;
        });

        $MICROCODE[FREE_MEM] = set_subname( FREE_MEM => sub ($cpu) {
            my $ptr = $cpu->pop;

            $cpu->heap->free( $ptr->value );
        });


        ## ----------------------------------------------------------
        ## Output
        ## ----------------------------------------------------------

        $MICROCODE[PUT] = set_subname( PUT => sub ($cpu) {
            my $arg = $cpu->pop;
            $cpu->sod->put( $arg );
        });

        $MICROCODE[GET_CHAR] = set_subname( GET_CHAR => sub ($cpu) {
            $cpu->push( $cpu->sid->get(VM::Types->CHAR) );
        });

        $MICROCODE[GET_INT] = set_subname( GET_INT => sub ($cpu) {
            $cpu->push( $cpu->sid->get(VM::Types->INT) );
        });

        $MICROCODE[GET_FLOAT] = set_subname( GET_FLOAT => sub ($cpu) {
            $cpu->push( $cpu->sid->get(VM::Types->FLOAT) );
        });

        ## ----------------------------------------------------------
        ## Stack Operaations
        ## ----------------------------------------------------------

        $MICROCODE[DUP] = set_subname( DUP => sub ($cpu) {
            $cpu->push( $cpu->peek );
        });

        $MICROCODE[POP] = set_subname( POP => sub ($cpu) {
            $cpu->pop;
        });

        $MICROCODE[PUSH] = set_subname( PUSH => sub ($cpu) {
            my $val = $cpu->next_op;
            $cpu->push( $val );
        });

        $MICROCODE[SWAP] = set_subname( SWAP => sub ($cpu) {
            my $v1 = $cpu->pop;
            my $v2 = $cpu->pop;
            $cpu->push( $v1 );
            $cpu->push( $v2 );
        });

        ## ----------------------------------------------------------

        (scalar @MICROCODE == scalar @OPCODE_NAMES)
            || die 'There must be microcode for each opcode, missing '
                   .(scalar @OPCODE_NAMES - scalar @MICROCODE).' opcodes';
    }
}
