cmake_minimum_required(VERSION 3.10)
project(facade_binary C)

add_library(helper SHARED src/helper.c)
target_compile_definitions(helper PRIVATE HELPER_SHARED_EXPORTS)
set_target_properties(
    helper
    PROPERTIES
        VERSION 3.4.5
        SOVERSION 3
        PUBLIC_HEADER include/helper.h
)
target_include_directories(helper PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

add_executable(app src/main.c)
target_include_directories(app PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
target_link_libraries(app PRIVATE helper)

install(TARGETS helper app
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
    PUBLIC_HEADER DESTINATION include
)
