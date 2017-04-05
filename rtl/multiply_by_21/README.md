# Origin

Unknown

# Company

Unknown

# Problem Statement

A constant, sparse integer is to be multiplied against an arbitrary
width random vector. Derive efficient logic to perform this
operation. (Sparse means that the vector has only a small number of
bits set).

# Commentary

Multiplication is simply repeated addition over differing radii. For a
sparse constant, multiplication can be carried out efficiently by
infering N adders (where N is the population count of the constant)
adding the i'th shifted version of the input (where 'i' is the
location of the bit in the constant vector).

Addition can be efficiently performed by using a CSA structure. Which
should be efficiently infered by repeated addition operators.
