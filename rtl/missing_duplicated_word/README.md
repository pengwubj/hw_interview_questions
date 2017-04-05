# Origin

# Company

Google

# Problem

Given an array with 2n+1 integer elements, n elements appear twice in arbitrary
places in the array and a single integer appears only once somewhere
inside. Find the lonely integer with O(n) operations and O(1) extra memory.

# Commentary

An even occurence of a variable can be detected by flipping a bit each time it
is sampled (zero occurences is considered even). For a SRAM containing 2N+1
entries, of width W, odd occurances of a variable can be detected by maintaining
a 2^W vector, and flipping the corresponding bit in the vector each time the
value is read from SRAM. After having queried the state table, provided the
input is not malformed, the non-duplicated value can be identified by encoding
the final 1 hot vector.

# Complexity

O(N) lookup operations are required. Lookup is linear with the number of table
entries. Recall that O(2N+1)=O(N), as one could mistakely assume that the 2N+1
table can only be queried using N operations..

O(1) state is required (with respect to N).

O(2^W) state is required with respect to W.
