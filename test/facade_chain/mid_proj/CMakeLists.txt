cmake_minimum_required(VERSION 3.10)
project(facade_chain_mid C)

include_directories(../include "$ENV{EXT_BUILD_DEPS}/include")
find_library(LEAF_LIB leaf PATHS "$ENV{EXT_BUILD_DEPS}/lib" NO_DEFAULT_PATH REQUIRED)

add_library(mid_shared SHARED ../src/mid.c)
add_library(mid_static STATIC ../src/mid.c)

target_compile_definitions(mid_shared PRIVATE MID_SHARED_EXPORTS)
target_link_libraries(mid_shared PRIVATE "${LEAF_LIB}")
target_link_libraries(mid_static PRIVATE "${LEAF_LIB}")

set_target_properties(mid_shared PROPERTIES OUTPUT_NAME mid)
set_target_properties(mid_static PROPERTIES OUTPUT_NAME mid)

if(WIN32)
  set_target_properties(mid_static PROPERTIES OUTPUT_NAME mid_static)
endif()

install(FILES ../include/mid.h DESTINATION include)
install(TARGETS mid_shared mid_static
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
)
