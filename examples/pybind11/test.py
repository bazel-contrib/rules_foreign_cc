# This example is taken for test and demonstration purposes from
# https://github.com/tdegeus/pybind11_examples/blob/master/01_py-list_cpp-vector/test.py

import example

A = [1.,2.,3.,4.]

B = example.modify(A)

print(B)