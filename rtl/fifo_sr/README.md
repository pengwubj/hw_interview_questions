# Origin

# Company

N/A

# Problem Statement

Construct a N-depth Queue of W-width using a shift-register
structure. Pop operations may be asynchronous to the pop strobe. The
structure must be power efficient.

# Commentary

A queue can be trivially implemented as a shift register. On each push
operation, all state in registers is shifted one step. Although
trivial, the unnecessary data movement results in increased power
consumption. Instead, the same effect can be realized by using a 1h
read/write strobe pointer into a static flop array. Clocks to the flop
array are gated for except when being written. 
