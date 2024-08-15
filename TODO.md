<!---------------------------------------------------------------------------->
# VM
<!---------------------------------------------------------------------------->



- ParseInt test might be interesting











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



