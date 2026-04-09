cmake_minimum_required(VERSION 3.15)

project(zlib-example)

if(DEFINED ZLIB_ROOT)
    file(GLOB _zlib_root_lib_entries "${ZLIB_ROOT}/lib/*")
    message(STATUS "ZLIB_ROOT='${ZLIB_ROOT}'")
    message(STATUS "ZLIB_ROOT/lib entries='${_zlib_root_lib_entries}'")
endif()

find_package(ZLIB REQUIRED)

# Print the imported target shape so the matrix can distinguish package-discovery
# bugs from later runtime staging issues.
foreach(prop
    IMPORTED_LOCATION
    IMPORTED_LOCATION_DEBUG
    IMPORTED_LOCATION_RELEASE
    IMPORTED_IMPLIB
    IMPORTED_IMPLIB_DEBUG
    IMPORTED_IMPLIB_RELEASE
    INTERFACE_LINK_LIBRARIES
)
    get_target_property(zlib_prop ZLIB::ZLIB ${prop})
    message(STATUS "ZLIB::ZLIB ${prop}='${zlib_prop}'")
endforeach()

set(SRCS zlib-example.cpp)

add_executable(${PROJECT_NAME} ${SRCS})

target_link_libraries(${PROJECT_NAME} ZLIB::ZLIB)

install(TARGETS ${PROJECT_NAME} DESTINATION bin)
