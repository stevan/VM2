<!---------------------------------------------------------------------------->
# VM
<!---------------------------------------------------------------------------->

## Serial I/O

- currently we have $sod and $sid as scalars
    - these should arrays, each it's own channel
        - $sid[0] == STDIN
        - $sod[0] == STDOUT
    - then you can add more channels if you want
    - this can be wired up by the VM
        - but handled in the Core

## Interrupts

- how do you handle interrupts from two different channels at the same time??

- Interrupts + multiple I/O channels can be used in a multi-core
  scenario to allow processors to communicate with one another
  in an async way

## Tests to Write

- ParseInt test might be interesting

<!---------------------------------------------------------------------------->


## Executable format

- the assembler should produce this format

## Loader

- this is a new object
    - it will consume the executable format
    - and load it into the CPU & memory

## Static Values

- this requires the Loader and Executable format first

## Struct Descriptions

<!---------------------------------------------------------------------------->
# Memory
<!---------------------------------------------------------------------------->

- ALLOC_MEM
    - it takes a stride right now, but that should be a compile-time calculated value
        - ALLOC_MEM, size_of(VM::Types->INT);
            - should probably export `INT` from Asssembly.pm
    - then a struct would look like ...
        - ALLOC_MEM, size_of(struct('Foo'));
    - all of this can be resolved at compile time since `size_of` is an assembler macro
        - and `struct` is also assembler lookup for the asm file header

## Block

- handle cases in the allocator
    - when there is no matching size
        - if smaller, then we can splice
            - leave the remainder in @freed
            - return the new sliced pointer

<!---------------------------------------------------------------------------->
# Clock timings
<!---------------------------------------------------------------------------->

A quick hack for a display .. which is really just a playback

```perl


my %used_colors;
my @colors;
my @timings;
foreach my ($op, $timing) ($vm->clock->timings) {
    #say sprintf "%15s : %f" => $op, $timing;
    push @timings => $timing;
    push @colors => $used_colors{ $op->to_string } //= [ map { int(rand(25)) * 10 } qw[ r g b ] ];

    #warn $timing, " ... ", ($timing * 100000);
}

#die;

my $wallclock = List::Util::sum(@timings);

my $height = 20;
my $stride = 120;
my $start  = 0;
my $end    = $start + $stride;
#die $#timings;
while (true) {

    $end = $#timings if $end >= $#timings;

    my @output = map { sprintf '%02d |' => $_ } reverse (0 .. $height);
    foreach my $idx ( $start .. $end ) {
        my $timing = $timings[$idx];
        my $t = int($height * ($timing * 100_000));

        my $m = sprintf "\e[48;2;%d;%d;%d;m \e[0m" => $colors[$idx]->@*;

        foreach my $i (0 .. $height) {
            $output[$i] .= ($i >= $t ? $m : ' ');
        }
    }
    say "\e[2J\e[H\n",
        (sprintf "wallclock: %s microseconds\n" => ($wallclock * 100_000)),
        join "\n" => @output;
    if (my $c = $ENV{CLOCK}) {
        Time::HiRes::sleep($c);
    } else {
        my $x = <>;
    }

    last if $end == $#timings;

    $start++;
    $end++;
}

#say "\n";

```



