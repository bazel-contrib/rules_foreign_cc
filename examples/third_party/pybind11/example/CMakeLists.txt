cmake_minimum_required(VERSION 2.8.12)
project(example)

find_package(pybind11)
pybind11_add_module(example example.cpp)

install(TARGETS example DESTINATION lib)

#example.cpython-35m-x86_64-linux-gnu