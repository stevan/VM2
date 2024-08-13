#!perl

use v5.40;
use experimental qw[ class ];

use Sub::Util ();

use VM::Internal::Tools;

use VM::Value::NULL;
use VM::Value::INT;
use VM::Value::FLOAT;
use VM::Value::CHAR;
use VM::Value::TRUE;
use VM::Value::FALSE;
use VM::Value::POINTER;

class VM::Opcodes {
    class VM::Opcodes::Opcode :isa(VM::Internal::Tools::Enum) {}

    our @OPCODES;
    BEGIN {
        @OPCODES = qw[
            CONST_NULL

            CONST_TRUE
            CONST_FALSE

            CONST_INT
            CONST_CHAR

            ADD_INT
            SUB_INT
            MUL_INT
            DIV_INT
            MOD_INT

            EQ_INT
            LT_INT
            GT_INT

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

            PRINT

            DUP
            POP
            SWAP

            HALT
        ];
        foreach my $i ( 0 .. $#OPCODES ) {
            no strict 'refs';
            my $op   = $OPCODES[$i];
            my $enum = VM::Opcodes::Opcode->new( int => $i++, label => $op );
            constant->import( $op => $enum );
        }
    }

    our @MICROCODE;
    BEGIN {
        $MICROCODE[HALT] = Sub::Util::set_subname( HALT => sub ($cpu) { $cpu->halt } );

        ## ----------------------------------------------------------
        ## Constants
        ## ----------------------------------------------------------

        $MICROCODE[CONST_NULL] = Sub::Util::set_subname( CONST_NULL => sub ($cpu) {
            $cpu->push( VM::Value::NULL->new );
        });

        $MICROCODE[CONST_INT] = Sub::Util::set_subname( CONST_INT => sub ($cpu) {
            my $int = $cpu->next_op;
            $cpu->push( $int );
        });

        $MICROCODE[CONST_CHAR] = Sub::Util::set_subname( CONST_CHAR => sub ($cpu) {
            my $char = $cpu->next_op;
            $cpu->push( $char );
        });

        $MICROCODE[CONST_TRUE] = Sub::Util::set_subname( CONST_TRUE => sub ($cpu) {
            $cpu->push( VM::Value::TRUE->new );
        });

        $MICROCODE[CONST_FALSE] = Sub::Util::set_subname( CONST_FALSE => sub ($cpu) {
            $cpu->push( VM::Value::FALSE->new );
        });

        $MICROCODE[IS_NULL] = Sub::Util::set_subname( IS_NULL => sub ($cpu) {
            my $value = $cpu->pop;
            $cpu->push( $value isa VM::Value::NULL ? VM::Value::TRUE->new : VM::Value::FALSE->new );
        });

        ## ----------------------------------------------------------
        ## Math
        ## ----------------------------------------------------------

        $MICROCODE[ADD_INT] = Sub::Util::set_subname( ADD_INT => sub ($cpu) {
            my $rhs = $cpu->pop;
            my $lhs = $cpu->pop;
            $cpu->push( VM::Value::INT->new( value => $lhs->value + $rhs->value ) );
        });

        $MICROCODE[SUB_INT] = Sub::Util::set_subname( SUB_INT => sub ($cpu) {
            my $rhs = $cpu->pop;
            my $lhs = $cpu->pop;
            $cpu->push( VM::Value::INT->new( value => $lhs->value - $rhs->value ) );
        });

        $MICROCODE[MUL_INT] = Sub::Util::set_subname( MUL_INT => sub ($cpu) {
            my $rhs = $cpu->pop;
            my $lhs = $cpu->pop;
            $cpu->push( VM::Value::INT->new( value => $lhs->value * $rhs->value ) );
        });

        $MICROCODE[DIV_INT] = Sub::Util::set_subname( DIV_INT => sub ($cpu) {
            my $rhs = $cpu->pop;
            my $lhs = $cpu->pop;
            if ( $rhs == 0 ) {
                return VM::Errors->ILLEGAL_DIVISION_BY_ZERO;
            }
            $cpu->push( VM::Value::INT->new( value => $lhs->value / $rhs->value ) );
        });

        $MICROCODE[MOD_INT] = Sub::Util::set_subname( MOD_INT => sub ($cpu) {
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

        $MICROCODE[EQ_INT] = Sub::Util::set_subname( EQ_INT => sub ($cpu) {
            my $rhs = $cpu->pop;
            my $lhs = $cpu->pop;
            $cpu->push( $lhs->value == $rhs->value ? VM::Value::TRUE->new : VM::Value::FALSE->new );
        });

        $MICROCODE[LT_INT] = Sub::Util::set_subname( LT_INT => sub ($cpu) {
            my $rhs = $cpu->pop;
            my $lhs = $cpu->pop;
            $cpu->push( $lhs->value < $rhs->value ? VM::Value::TRUE->new : VM::Value::FALSE->new );
        });

        $MICROCODE[GT_INT] = Sub::Util::set_subname( GT_INT => sub ($cpu) {
            my $rhs = $cpu->pop;
            my $lhs = $cpu->pop;
            $cpu->push( $lhs->value > $rhs->value ? VM::Value::TRUE->new : VM::Value::FALSE->new );
        });

        ## ----------------------------------------------------------
        ## Jumps
        ## ----------------------------------------------------------

        $MICROCODE[JUMP] = Sub::Util::set_subname( JUMP => sub ($cpu) {
            my $addr = $cpu->next_op;
            $cpu->jump_to( $addr->address );
        });

        $MICROCODE[JUMP_IF_FALSE] = Sub::Util::set_subname( JUMP_IF_FALSE => sub ($cpu) {
            my $addr = $cpu->next_op;
            my $bool = $cpu->pop;
            if ( $bool isa VM::Value::FALSE ) {
                $cpu->jump_to( $addr->address );
            }
        });

        $MICROCODE[JUMP_IF_TRUE] = Sub::Util::set_subname( JUMP_IF_TRUE => sub ($cpu) {
            my $addr = $cpu->next_op;
            my $bool = $cpu->pop;
            if ( $bool isa VM::Value::TRUE ) {
                $cpu->jump_to( $addr->address );
            }
        });

        ## ----------------------------------------------------------
        ## subroutine calls
        ## ----------------------------------------------------------

        $MICROCODE[LOAD_ARG] = Sub::Util::set_subname( LOAD_ARG => sub ($cpu) {
            my $offset = $cpu->next_op;
            $cpu->push( $cpu->stack_index(($cpu->fp - 3) - $offset) );
        });

        $MICROCODE[CALL] = Sub::Util::set_subname( CALL => sub ($cpu) {
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

        $MICROCODE[RETURN] = Sub::Util::set_subname( RETURN => sub ($cpu) {
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

        $MICROCODE[LOAD] = Sub::Util::set_subname( LOAD => sub ($cpu) {
            my $offset = $cpu->next_op;
            $cpu->push( $cpu->stack_index( $cpu->fp + $offset ) );
        });

        $MICROCODE[STORE] = Sub::Util::set_subname( STORE => sub ($cpu) {
            my $value  = $cpu->pop;
            my $offset = $cpu->next_op;
            $cpu->stack_index( $cpu->fp + $offset ) = $value;
        });

        ## ----------------------------------------------------------
        ## Memory
        ## ----------------------------------------------------------

        $MICROCODE[ALLOC_MEM] = Sub::Util::set_subname( ALLOC_MEM => sub ($cpu) {
            my $size   = $cpu->pop;
            my $stride = $cpu->next_op;

            my $ptr = $cpu->heap->alloc( $size->value, $stride );
            $cpu->push( VM::Value::POINTER->new( value => $ptr ) );
        });

        $MICROCODE[LOAD_MEM] = Sub::Util::set_subname( LOAD_MEM => sub ($cpu) {
            my $ptr    = $cpu->pop;
            my $offset = $cpu->pop;

            $cpu->push( $cpu->heap->resolve( $ptr->value->index( $offset->value ) ) );
        });

        $MICROCODE[STORE_MEM] = Sub::Util::set_subname( STORE_MEM => sub ($cpu) {
            my $ptr    = $cpu->pop;
            my $offset = $cpu->pop;
            my $value  = $cpu->pop;

            $cpu->heap->resolve( $ptr->value->index( $offset->value ) ) = $value;
        });

        $MICROCODE[FREE_MEM] = Sub::Util::set_subname( FREE_MEM => sub ($cpu) {
            my $ptr = $cpu->pop;

            $cpu->heap->free( $ptr->value );
        });


        ## ----------------------------------------------------------
        ## Output
        ## ----------------------------------------------------------

        $MICROCODE[PRINT] = Sub::Util::set_subname( PRINT => sub ($cpu) {
            my $arg = $cpu->pop;
            #print $arg->to_string;
        });

        ## ----------------------------------------------------------
        ## Stack Operaations
        ## ----------------------------------------------------------

        $MICROCODE[DUP] = Sub::Util::set_subname( DUP => sub ($cpu) {
            $cpu->push( $cpu->peek );
        });

        $MICROCODE[POP] = Sub::Util::set_subname( POP => sub ($cpu) {
            $cpu->pop;
        });

        $MICROCODE[SWAP] = Sub::Util::set_subname( SWAP => sub ($cpu) {
            my $v1 = $cpu->pop;
            my $v2 = $cpu->pop;
            $cpu->push( $v1 );
            $cpu->push( $v2 );
        });

        ## ----------------------------------------------------------

        (scalar @MICROCODE == scalar @OPCODES)
            || die 'There must be microcode for each opcode, missing '
                   .(scalar @OPCODES - scalar @MICROCODE).' opcodes';
    }
}
