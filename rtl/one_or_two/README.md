# one_or_two

# Question

For a given logic vector, of arbitrary length, derive logic that detects the
following conditions:

* 0-bits are set in the vector
* 1-bit is set in the vector
* ``>=``2-bits are set in the vector

Do so in a means that is efficient in terms of logic utilization and independent
of vector length.

# Commentary

This question is designed to illustrate a candidates understating of basic logic
concepts.

* 0-bits are set in the vector

This can be derived trivially by the following code:
~~~
always_comb has_set_0 = (A == '0);
~~~
or
~~~
always_comb has_set_0 = (~|A);
~~~

In both cases, this logic should synthesize to an NOR-reduction operation on the
input vector. This can be computed trivially and inferred through Verilog
independently of the length of A.

* 1-bit is set in the vector

The presence of set bits in the vector can be found trivially as:
~~~
always_comb has_set_at_least_1 = (|A);
~~~

the OR-reduction of the input vector. This does not indicate however whether
only one bit is set in the vector. It turns out that this can be computed as:
~~~
always_comb only_1_bit_set = ~|(A & (A - 1));
~~~

This relation is true only if A is a one-hot vector.

* ``>=``2-bits are set in the vector

Derived as a function of the prior logic, the condition can be calculated as:
~~~
always_comb has_set_more_than_1 = (~has_set_0) & (~has_set_1);
~~~

Additionally, the candidate may wish to qualify the condition such that its
assertion is defeated if the logic vector is only 1-bit in length.
