#include <iostream>
#include <stdexcept>
#include <string>

#include "mylib.h"

int main(int argc, char* argv[]) {
    // Test the hello_mylib function
    std::string result = hello_mylib();
    if (result != "Hello from MyLib!") {
        throw std::runtime_error("Wrong result from hello_mylib: " + result);
    }

    // Test the add_numbers function
    int math_result = add_numbers(5, 3);
    if (math_result != 8) {
        throw std::runtime_error("Wrong math_result from add_numbers: " +
                                 std::to_string(math_result));
    }

    std::cout << "Everything's fine!";
    return 0;
}
