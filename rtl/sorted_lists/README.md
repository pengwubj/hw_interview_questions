# Origin

Networking Match/Action data paths

# Company

Unknown

# Problem Statement

M-lists (M=64) are maintained. The lists are ordered, although the ordering (GT
or LT) is irrelevant. Each entry in the list maintains a {KEY, SIZE} pair. The
list is ordered on the value of KEY. SIZE is considered a payload which is
simply retained by the machine and returned to the client.

List state can be modified using the following commands:

* CLEAR: All State associated with the LIST is cleared (reset to
  initial state).

* ADD: A {KEY, SIZE} pair is added to the LIST

* DELETE: A {KEY, SIZE} pair is deleted from the LIST based upon an input
  KEY operand.  If the KEY is not present, an error is signalled.

* REPLACE: The SIZE field of a {KEY, SIZE} pair is replaced based
  upon an input KEY operand.

A QUERY interface is present. From this a particular LIST is addressed and the
N'th largest/smallest returned.

Each list can be modified "every other cycle". The Query bus may be active at
the time a list is modified however it can be assumed that a list being actively
modified shall not be queried.


# Performance Objectives/Actuals

Objective: List state can be updated "every-other-cycle"; therefore a
utilization of around 50% is required. List state can be queried on each cycle.

# Implementation

The question is purposefully misleading because it is worded in such a fashion
that it implies that state must be internally maintained using a Linked List
structure. This is possible, however it is not possible to achieve the stated
performance objectives using a linked list. The DELETE and REPLACE operations
too suggest that some associative addressing is required as in this case an
operation is performed based upon the KEY match. To perform this using a LL
structure is O(N) with the length of the list.

The proposed implementation maintains the list structure as a tuple of entries
in a table. The entries are unordered. ADD, DELETE, REPLACE, CLEAR commands are
trivially implemented based upon an associative "HIT" operation and writeback.

The Query bus is implemented by performing a lookup on the LIST state and
combinatorially sorting all entries on the KEY. The N'th largest/smallest can be
trivially derived.

Inbound updates commands and coincident with Query operations. This results in a
structural hazard on the port count the RAMs used to maintain the table. The
table is therefore duplicated to increase port count as necessary. The UPDATE
logic maintains ownership of the table, therefore forwarding is unnecessary.

# Verification Methodology

A C++ behavioral model is implemented to emulate the machine. A randomized
series of update commands are generated based upon the machine state and
injected into RTL. The behavioral model is updated in parallel with the
application of UPDATE stimulus. Stimulus is appropriately constrained.

Post-initialization, query commands are emitted and responses checked against
expected behavior.

# PD

The target operating clock frequency of the block is 150-170 MHz. Two
key optimizations

* The update pipeline is not completely forwarded. Consequently, it
  cannot support back to back update commands to the same ID. The
  pipeline can support back-to-back commands to differing ID.

* The sort network is pipelined after each comparison operation
  (accounting for parallelism between operations). This is a fairly
  lengthy comparison, 64b subtraction, and may therefore be
  slow. There are no requirements on latency, therefore pipeline is
  applied.

# Commentary
