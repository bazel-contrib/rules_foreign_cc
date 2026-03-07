load("@rules_foreign_cc//foreign_cc:defs.bzl", "cmake")

# Simple test to verify set_file_prefix_map defaults to True
cmake(
    name = "test_default_file_prefix_map",
    lib_source = "@cmake_hello_world_lib//:srcs",
    # This should implicitly use set_file_prefix_map = True (the new default)
    out_static_libs = ["libhello.a"],
)

# Test explicit override to False  
cmake(
    name = "test_disabled_file_prefix_map", 
    lib_source = "@cmake_hello_world_lib//:srcs",
    # Explicitly disable set_file_prefix_map
    set_file_prefix_map = False,
    out_static_libs = ["libhello.a"],
)