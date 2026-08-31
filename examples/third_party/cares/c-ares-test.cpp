#include <string.h>

#include <iostream>
#include <stdexcept>

#include "ares.h"

int main(int argc, char* argv[]) {
    int version = 0;
    const char* strVersion = ares_version(&version);
    if (strcmp(strVersion, "1.34.6") != 0) {
        throw std::runtime_error("Wrong version: " + std::string(strVersion));
    }
    std::cout << "C-ares version: " << strVersion;
}
