cmake_minimum_required(VERSION 3.10)
project(facade_static_library C)

add_library(combo STATIC src/combo.c)
target_include_directories(combo PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

add_library(combo_shared SHARED src/combo.c)
target_compile_definitions(combo_shared PRIVATE COMBO_SHARED_EXPORTS)
target_include_directories(combo_shared PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

install(TARGETS combo
    ARCHIVE DESTINATION lib
)
install(TARGETS combo_shared
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)
install(FILES include/combo.h DESTINATION include)
