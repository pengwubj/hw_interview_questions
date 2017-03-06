# gates_from_MUX2X1

# Question

Using just a simple 2-input multiplexor, construct equivalent 2-input INV, AND,
OR and XOR gates.

# Commentary

The question is fairly straightforward considering that it is also possible to
tie MUX inputs to VDD and GND.

* INV

Mux selects between inputs 0 and 1. Input 0 is tied to true; Input 1 is tied to
false. The MUX selection line acts as the input to the INV.

* AND

Similarly, to calculate AB, A is set as the MUX select line, Input 1 is set a
B. The output of the MUX is true only when both A and B are true.

* OR

Extending the AND solution: Y is derive as the output of the MUX gate. MUX
select is driven by B. Input 0 is driven to A, Input 1 is driven to B.

* XOR

The XOR gate cannot be computed directly from a single MUX gate. Instead, it
must be computed from the previously derived GATE primitives using the familiar
formula for XOR: A!B + !AB.
