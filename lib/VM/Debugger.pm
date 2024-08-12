#!perl

use v5.40;
use experimental qw[ class ];

use List::Util ();

use VM::Debugger::Stack;
use VM::Debugger::Memory;
use VM::Debugger::Code;

class VM::Debugger {
    field $vm :param :reader;

    field $code;
    field $stack;
    field $memory;

    ADJUST {
        $code   = VM::Debugger::Code   ->new( vm => $vm );
        $stack  = VM::Debugger::Stack  ->new( vm => $vm );
        $memory = VM::Debugger::Memory ->new( vm => $vm );
    }

    method draw {
        my @code   = $code->draw;
        my @stack  = $stack->draw;
        my @memory = $memory->draw;

        my $code_width   = $code->width;
        my $stack_width  = $stack->width;
        my $memory_width = $memory->width;

        my $code_height   = $#code;
        my $stack_height  = $#stack;
        my $memory_height = $#memory;

        my $height = List::Util::max( $code_height, $stack_height, $memory_height );

        my @out;
        foreach my $i ( 0 .. $height ) {
            push @out => join ' | ' => (
                $code[$i]   // (' ' x   $code_width),
                $stack[$i]  // (' ' x  $stack_width),
                $memory[$i] // (' ' x $memory_width),
            );
        }
        return @out;
    }
}
