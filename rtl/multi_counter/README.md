# Origin

Unknown

# Company

Fungible/Google

# Problem Statement

Maintain a set of counters that can be incremented, decremented of initialized
based upon in incoming comamnd. The counters are implemented in a single
dual-ported synchronous SRAM (or register file). Implement a pipeline to compute
updates to the counters such that commands can be consumed at the rate of 1 per
cycle.

# Commentary

This question is designed to present an understanding of basic pipelining
concepts. In particular, the requirement to support back-to-back commands
(possibly referencing the same counter), necessitates the use of oprand
forwarding.

The pipeline design can be relatively trivial as there is no need to support
replay, stall conditions, committal and/or retirement states.
