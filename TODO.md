# VM

## Output buffer

- this is what `PRINT` should use

## Executable format

- the assembler should produce this format

## Loader

- this is a new object
    - it will consume the executable format
    - and load it into the CPU & memory

## Static Values

- this requires the Loader and Executable format first

# Memory

## Block

- handle cases in the allocator
    - when there is no matching size
        - if smaller, then we can splice
            - leave the remainder in @freed
            - return the new sliced pointer

## Pointers

- create pointer slices
    - this might help with the memory allocator

