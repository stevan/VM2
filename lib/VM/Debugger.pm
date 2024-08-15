#!perl

use v5.40;
use experimental qw[ class ];

use importer 'List::Util'  => qw[ max sum ];
use importer 'Time::HiRes' => qw[ sleep ];

use VM::Debugger::Stack;
use VM::Debugger::Memory;
use VM::Debugger::Code;

class VM::Debugger {
    field $vm :param :reader;

    field $code;
    field $stack;
    field $heap;

    ADJUST {
        $code  //= VM::Debugger::Code   ->new( vm => $vm );
        $stack //= VM::Debugger::Stack  ->new( vm => $vm );
        $heap  //= VM::Debugger::Memory ->new( block => $vm->heap );
    }

    method call {
        print "\e[2J\e[H\n";
        say join "\n" => $self->draw;
        if (my $sleep = $ENV{CLOCK}) {
            sleep($sleep);
        } else {
            my $x = <>;
        }
    }

    method draw {
        my @code  = $code->draw;
        my @stack = $stack->draw;
        my @heap  = $heap->draw;

        my $code_width  = $code->width;
        my $stack_width = $stack->width;
        my $heap_width  = $heap->width;

        my $code_height  = $#code;
        my $stack_height = $#stack;
        my $heap_height  = $#heap;

        my $height = max( $code_height, $stack_height, $heap_height );

        $stack->set_height( $height );
        $stack_height = $height;

        my @out;

        push @out => (join ' ' =>
            ('╭── Code '  .('─' x ($code_width  - 7)).'─╮'),
            ('╭── Stack ' .('─' x ($stack_width - 8)).'─╮'),
            ('╭── Heap '  .('─' x ($heap_width  - 7)).'─╮'),
        );

        foreach my $i ( 0 .. $height ) {
            push @out => (join ' ' => map { sprintf '│ %s │' => $_ } (
                $code[$i]  // (' ' x  $code_width),
                $stack[$i] // (' ' x $stack_width),
                $heap[$i]  // (' ' x  $heap_width),
            ));
        }

        push @out => (join ' ' =>
            ('╰─'.('─' x $code_width) .'─╯'),
            ('╰─'.('─' x $stack_width).'─╯'),
            ('╰─'.('─' x $heap_width) .'─╯'),
        );

        my $width = sum( $code_width, $stack_width, $heap_width ) + 10;

        push @out => (
            ('╭── Input '  .('─' x ($width  - 8)).'─╮'),
            ('│ '.(sprintf "%-${width}s" => join '' => map $_->value, $vm->sid->buffer).' │'),
            ('╰─'.           ('─' x $width)       .'─╯'),
        );

        push @out => (
            ('╭── Output '  .('─' x ($width  - 9)).'─╮'),
            ('│ '.(sprintf "%-${width}s" => join '' => map $_->value, $vm->sod->buffer).' │'),
            ('╰─'.           ('─' x $width)       .'─╯'),
        );

        return @out;
    }
}
