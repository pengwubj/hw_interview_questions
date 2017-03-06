# Count Ones (population count)

# Question

Given an input logic vector, compute the number of set bits (the population
count).

# Commentary

The population count function is very common in software, although perhaps more
infrequent in logic design. Presented here is simply a question that may be
poised to gain an appreciation of a candidates ability to write synthesizable
Verilog and to understand the relative trade-offs between different solutions.

Presented are three possible solutions to this problem.

## R0 - Gated Adders

For each bit in the vector, a M = LOG2(A) + 1 adder is infered. The input to
each adder is 'b1 gated upon the presence of a 1 in the current bit position of
A. This solution is relatively trivial however scales poorly with N, M-bit
adders infered.

## R1 - Look Up Table

Instead, bit counts can be pre-computed for certain vector lengths. Although the
approach remains similar to that of the prior solution, the number of adders can
be reduced by W, where W is the width of the LUT.

In the presented solution, LUT functionality is implemented using a
combinatorial logic cone derived from A. It is not implemented as a specific ROM
macro as may have been implied.

## R2 - Carry Save Adder (CSA)

A Carry Save Adder (CSA) can be infered using 3:2 compressor blocks. Such blocks
are commonly optimized in most standard cell libraries and are therefore area
and performance efficient. The final population counter is derived by infering a
final full-adder using the standard CSA approach. This solution, although the
most area and performance efficient, is slightly harder to code, and cannot be
easily parameterized for reuse.
