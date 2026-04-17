cmake_minimum_required(VERSION 3.10)
project(facade_chain_leaf C)

add_library(leaf_shared SHARED ../src/leaf.c)
add_library(leaf_static STATIC ../src/leaf.c)

target_compile_definitions(leaf_shared PRIVATE LEAF_SHARED_EXPORTS)
target_include_directories(leaf_shared PUBLIC ../include)
target_include_directories(leaf_static PUBLIC ../include)

set_target_properties(leaf_shared PROPERTIES OUTPUT_NAME leaf)
set_target_properties(leaf_static PROPERTIES OUTPUT_NAME leaf)

if(WIN32)
  set_target_properties(leaf_static PROPERTIES OUTPUT_NAME leaf_static)
endif()

install(FILES ../include/leaf.h DESTINATION include)
install(TARGETS leaf_shared leaf_static
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
)
