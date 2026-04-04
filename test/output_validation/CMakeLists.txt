cmake_minimum_required(VERSION 3.10)
project(output_validation_repro C)

add_library(repro STATIC repro.c)
target_include_directories(repro PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

install(TARGETS repro ARCHIVE DESTINATION lib)
install(FILES repro.h DESTINATION include)
