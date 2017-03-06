# Asynchronous FIFO

# Question

Design (and constrain) a FIFO/Queue module where the PUSH interface is
asynchronous to the POP interface.

# Answer

The design of asynchronous FIFO is well documented. Read-/Write- pointers are
communicated across the clock boundary using GRAY encoding. GRAY encoding
presents the key advantage that upon increment or decrement, at most one bit
shall change. By result of this, downstream resynchronization logic shall
capture either the new value or the old value. In contrast, in a traditional
binary scheme, the old, the new and any intermediate states may be captured.

The token gotcha in this example is the infamous "Qualcomm bug". GRAY pointers
are computed as a combinatorial function of the standard binary pointers. After
looking at waveforms in VCS, it is easy to forget that such combinatorial logic
does not compute its result at one precise instand in time. All logic cones,
even GRAY encoded logic, require some time to compute their result. Before that
point, the result is undefined. Here, the term undefined also means
wrong. Applying a standard synchronizing approach to the GRAY cone can result in
invalid values. This is by consequence of the differing settling times and skew
at each GRAY wire. The solution is to FLOP the computed GRAY code using the
LAUNCH clock before it is passed to the CAPTURING clocks resynchronizer.

## NOTE:
Apparently, Qualcomm had to respin a chip after the additional GRAY flop was
omitted from a asynchronous FIFO used throughout the chip.
