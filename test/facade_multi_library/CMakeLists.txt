cmake_minimum_required(VERSION 3.10)
project(facade_multi_library C)

add_library(first SHARED src/first.c)
target_compile_definitions(first PRIVATE FIRST_SHARED_EXPORTS)
set_target_properties(
    first
    PROPERTIES
        VERSION 1.0.0
        SOVERSION 1
        PUBLIC_HEADER include/first.h
)
target_include_directories(first PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

add_library(first_static STATIC src/first.c)
if(WIN32)
    set_target_properties(first_static PROPERTIES OUTPUT_NAME first_static)
else()
    set_target_properties(first_static PROPERTIES OUTPUT_NAME first)
endif()
target_include_directories(first_static PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

add_library(second SHARED src/second.c)
target_compile_definitions(second PRIVATE SECOND_SHARED_EXPORTS)
set_target_properties(
    second
    PROPERTIES
        VERSION 2.0.0
        SOVERSION 2
        PUBLIC_HEADER include/second.h
)
target_include_directories(second PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

add_library(second_static STATIC src/second.c)
if(WIN32)
    set_target_properties(second_static PROPERTIES OUTPUT_NAME second_static)
else()
    set_target_properties(second_static PROPERTIES OUTPUT_NAME second)
endif()
target_include_directories(second_static PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

install(TARGETS first first_static second second_static
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
    PUBLIC_HEADER DESTINATION include
)
