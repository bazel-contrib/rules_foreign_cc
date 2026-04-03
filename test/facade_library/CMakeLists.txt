cmake_minimum_required(VERSION 3.10)
project(facade_library C)

add_library(demo SHARED src/demo.c)
target_compile_definitions(demo PRIVATE DEMO_SHARED_EXPORTS)
set_target_properties(
    demo
    PROPERTIES
        VERSION 1.2.3
        SOVERSION 1
        PUBLIC_HEADER include/demo.h
)
target_include_directories(demo PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

add_library(demo_static STATIC src/demo.c)
if(WIN32)
    set_target_properties(demo_static PROPERTIES OUTPUT_NAME demo_static)
else()
    set_target_properties(demo_static PROPERTIES OUTPUT_NAME demo)
    add_custom_command(
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/libdemo.pic.a
        COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:demo_static> ${CMAKE_CURRENT_BINARY_DIR}/libdemo.pic.a
        DEPENDS demo_static
    )
    add_custom_target(demo_pic_static ALL DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/libdemo.pic.a)
endif()
target_include_directories(demo_static PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

install(TARGETS demo demo_static
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
    PUBLIC_HEADER DESTINATION include
)
install(DIRECTORY include/prefixed DESTINATION include)
if(NOT WIN32)
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libdemo.pic.a DESTINATION lib)
endif()
