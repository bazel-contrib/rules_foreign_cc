cmake_minimum_required(VERSION 2.8.4)

set(LIBB_SRC libb.cpp libb.h)

add_library(libb_static STATIC ${LIBB_SRC})

find_package(LIBA REQUIRED NAMES alib liba libliba)

# LIBA_INCLUDE_DIRS is not set, so giving the path relative to liba_config.cmake
# would be happy to improve that
target_link_libraries(libb_static PUBLIC ${LIBA_DIR}/../../../lib/libliba.a)
target_include_directories(libb_static PUBLIC ${LIBA_DIR}/../../../include)

set_target_properties(libb_static PROPERTIES OUTPUT_NAME "libb")

set(LIBRARY_OUTPUT_PATH ${PROJECT_BINARY_DIR}/lib)

install(TARGETS libb_static ARCHIVE DESTINATION lib)

install(FILES libb.h DESTINATION include)