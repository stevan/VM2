# VM

## Block

- handle cases in the allocator
    - when there is no matching size
        - if smaller, then we can splice
            - leave the remainder in @freed
            - return the new sliced pointer

## Pointers

- create pointer slices
    - this might help with the memory allocator

