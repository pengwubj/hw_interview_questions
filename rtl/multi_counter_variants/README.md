# Origin

# Company

Google

# Problem

Maintain a set of counters that can be incremented, decremented of initialized
based upon in incoming command.

# Commentary

There are multiple possible solutions to the question as posed each
varying in complexity. The correct solution largely depends upon the
counter count and desired clock frequency.

Three solutions are presented:

* __Simple Flop Table__

  The simplest of the three solutions solves the problem by
  maintaining counter state entirely in flops. State is muxed by
  command id, modified and written back in one cycle. This is fairly
  straight forward however it suffers from, 1) the mux operation on
  the initial state lookup and 2) the consequent writeback to the
  state table. In 1) there is an N-to-1 mux, in 2) there is a O(N)
  fan-out at the output of the adder/subtractor. By consequence of
  this, the propose solution perhaps suffers from lower overall
  achievable clock frequency and may not be scalable to large N.

* __Multiple Engines__

  The second approach is to, similarly, maintain state in flops but
  replicate state update logic with each context. At the cost of some
  area overhead, the solution presented can be scaled to a larger N
  although there remains some fan-out issues on the command interface
  and on the output MUX.

* __Pipeline__

  The third, and most effiicent solution (but also the most complex),
  is to maintain state within a dual-ported synchronous SRAM. A
  pipeline is implemented around SRAM to manage lookup and writeback
  operations. This solution is largely invariant to changes in N and
  is capable of achieving a good Fmax.


# NOTES

In modern geometries, the transition to a dedicated SRAM module is
typically only justified when the number of bits to be retain exceeds
(on the order of) 1k-10kbits. Otherwise, a FF based structure is more
efficient in terms of area. Largely, modern geometries are quite
forgiving when it comes to synthesizing large FF-based arrays,
although this -of course- largely depends upon the particular
application.
