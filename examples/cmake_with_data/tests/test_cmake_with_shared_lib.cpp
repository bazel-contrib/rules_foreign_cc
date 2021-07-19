#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>

void test_opening_file(std::string path)
{
    std::ifstream data_file(path);
    if (!data_file.good())
    {
        throw std::runtime_error("Could not open file: " + path);
    }

    data_file.close();
}

int main(int argc, char* argv[])
{
    // Make sure the expectd shared library is available
#ifdef _WIN32
    test_opening_file(".\\cmake_with_data\\lib_b\\lib_b.dll");
#else
    test_opening_file("./cmake_with_data/lib_b/liblib_b.so");
#endif
    std::cout << "Everything's fine!";
}
