cmake_minimum_required(VERSION 2.8.4)

set(LIBB_SRC libb.cpp libb.h)

add_library(libb_static ${LIBB_SRC})
set_target_properties(libb_static PROPERTIES OUTPUT_NAME "b")
IF (WIN32)
  set_target_properties(libb_static PROPERTIES ARCHIVE_OUTPUT_NAME "libb")
ELSE()
  set_target_properties(libb_static PROPERTIES ARCHIVE_OUTPUT_NAME "b")
ENDIF()

find_package(LIBA NAMES alib liba libliba)

# LIBA_INCLUDE_DIRS is not set, so giving the path relative to liba_config.cmake
# would be happy to improve that
if (LIBA_PATH)
  target_link_libraries(libb_static PUBLIC ${LIBA_PATH})
else()
  find_library(LIBA_LIB NAMES a)
  message(STATUS "Found liba ${LIBA_LIB}")
  target_link_libraries(libb_static PUBLIC ${LIBA_LIB})
endif()

target_include_directories(libb_static PUBLIC ${LIBA_DIR}/include)

set(LIBRARY_OUTPUT_PATH ${PROJECT_BINARY_DIR}/lib)

install(TARGETS libb_static ARCHIVE DESTINATION lib LIBRARY DESTINATION lib)

install(FILES libb.h DESTINATION include)
