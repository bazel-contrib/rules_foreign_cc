// This example is taken for test and demonstration purposes from
// https://github.com/tdegeus/pybind11_examples/blob/master/01_py-list_cpp-vector/example.cpp
#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include <vector>

// ----------------
// Regular C++ code
// ----------------

// multiply all entries by 2.0
// input:  std::vector ([...]) (read only)
// output: std::vector ([...]) (new copy)
std::vector<double> modify(const std::vector<double>& input)
{
  std::vector<double> output;

  std::transform(
    input.begin(),
    input.end(),
    std::back_inserter(output),
    [](double x) -> double { return 2.*x; }
  );

  // N.B. this is equivalent to (but there are also other ways to do the same)
  //
  // std::vector<double> output(input.size());
  //
  // for ( size_t i = 0 ; i < input.size() ; ++i )
  //   output[i] = 2. * input[i];

  return output;
}

// ----------------
// Python interface
// ----------------

namespace py = pybind11;

PYBIND11_MODULE(example,m)
{
  m.doc() = "pybind11 example plugin";

  m.def("modify", &modify, "Multiply all entries of a list by 2.0");
}