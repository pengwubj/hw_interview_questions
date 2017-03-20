# Increment

# Question

Derive code to detect the first 0 in an input vector and to invert it, and all
preceding bits. What function does the logic perform?

# Commentary

Code to compute this function is presented.

It turns out, non-obviously, that this function actually computes an
increment-by-1 function on the input vector. It remains subject to debate the
advantage that such logic would have over the inference of a traditional
full-adder. Additionally, the complexity of the resultant code obscures the fact
that it computes a trivially and well-known function. In this case, it would
almost always be advisible for the logic designer to write a simple increment
function and all synthesize to infer the most efficient structure at the
gate-level.
