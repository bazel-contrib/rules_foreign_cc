cmake_minimum_required(VERSION 3.10)
project(OutputGroupsExample)

# Create a simple library
add_library(example_lib src/example.c)

# Create a simple executable
add_executable(example_tool src/main.c)
target_link_libraries(example_tool example_lib)

# Install targets
install(TARGETS example_lib example_tool
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
)

# Install headers
install(FILES src/example.h DESTINATION include)

# Install documentation
install(FILES README.txt DESTINATION share/doc/example)