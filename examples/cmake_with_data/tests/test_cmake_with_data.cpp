#include "lib_a.h"

#include <iostream>
#include <string>

int main(int argc, char* argv[])
{
#ifdef _WIN32
    std::string result = hello_data(".\\cmake_with_data\\cmake_with_data.txt");
#else
    std::string result = hello_data("./cmake_with_data/cmake_with_data.txt");
#endif
    if (result != "Hallo welt!")
    {
        throw std::runtime_error("Wrong result: " + result);
    }
    std::cout << "Everything's fine!";
}
