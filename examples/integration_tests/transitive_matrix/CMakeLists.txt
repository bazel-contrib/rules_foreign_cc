cmake_minimum_required(VERSION 3.15)

project(transitive_cc_foreign_libarchive_matrix C)

set(LIBARCHIVE_LIBRARY_NAME "archive" CACHE STRING "Library name to find for libarchive")
set(ZLIB_LIBRARY_NAME "" CACHE STRING "Optional library name to find for zlib")

if(APPLE)
    set(CMAKE_INSTALL_NAME_DIR "@rpath")
    set(CMAKE_MACOSX_RPATH ON)
endif()

function(matrix_add_dependency target library_name header_name)
    find_library(
        APP_FOUND_LIBRARY
        NAMES ${library_name}
        REQUIRED
    )
    find_path(
        APP_FOUND_INCLUDE_DIR
        NAMES ${header_name}
        REQUIRED
    )
    target_link_libraries(${target} PRIVATE "${APP_FOUND_LIBRARY}")
    target_include_directories(${target} PRIVATE "${APP_FOUND_INCLUDE_DIR}")
    unset(APP_FOUND_LIBRARY CACHE)
    unset(APP_FOUND_INCLUDE_DIR CACHE)
endfunction()

function(matrix_add_optional_dependency target library_name header_name)
    if(NOT library_name)
        return()
    endif()
    find_library(APP_FOUND_LIBRARY NAMES ${library_name})
    find_path(APP_FOUND_INCLUDE_DIR NAMES ${header_name})
    if(APP_FOUND_LIBRARY AND APP_FOUND_INCLUDE_DIR)
        target_link_libraries(${target} PRIVATE "${APP_FOUND_LIBRARY}")
        target_include_directories(${target} PRIVATE "${APP_FOUND_INCLUDE_DIR}")
    endif()
    unset(APP_FOUND_LIBRARY CACHE)
    unset(APP_FOUND_INCLUDE_DIR CACHE)
endfunction()

add_executable(app app.c)
matrix_add_dependency(app "${LIBARCHIVE_LIBRARY_NAME}" archive.h)
matrix_add_optional_dependency(app "${ZLIB_LIBRARY_NAME}" zlib.h)
if(CMAKE_DL_LIBS)
    target_link_libraries(app PRIVATE "${CMAKE_DL_LIBS}")
endif()
install(TARGETS app RUNTIME DESTINATION bin)
