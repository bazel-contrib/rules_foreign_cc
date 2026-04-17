cmake_minimum_required(VERSION 3.10)
project(facade_chain_top C)

include_directories(../include "$ENV{EXT_BUILD_DEPS}/include")
find_library(MID_LIB mid PATHS "$ENV{EXT_BUILD_DEPS}/lib" NO_DEFAULT_PATH REQUIRED)

add_library(top_shared SHARED ../src/top.c)
add_library(top_static STATIC ../src/top.c)

target_compile_definitions(top_shared PRIVATE TOP_SHARED_EXPORTS)
target_link_libraries(top_shared PRIVATE "${MID_LIB}")
target_link_libraries(top_static PRIVATE "${MID_LIB}")

set_target_properties(top_shared PROPERTIES OUTPUT_NAME top)
set_target_properties(top_static PROPERTIES OUTPUT_NAME top)

if(WIN32)
  set_target_properties(top_static PROPERTIES OUTPUT_NAME top_static)
endif()

install(FILES ../include/top.h DESTINATION include)
install(TARGETS top_shared top_static
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
)
