cmake_minimum_required(VERSION 3.10)
project(hello LANGUAGES CXX)
add_library(hello STATIC example.cc)
install(TARGETS hello ARCHIVE DESTINATION lib)
