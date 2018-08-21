// The code is adopted from https://github.com/c-ares/c-ares/blob/master/test/ares-test-parse.cc
// for testing purposes
#include "ares.h"

#include <iostream>
#include <string.h>

int main(int argc, char* argv[])
{
  int version = 0;
  const char* strVersion = ares_version(&version);
  if (strcmp(strVersion, "1.14.0") != 0) {
    throw std::runtime_error("Wrong version: " + std::string(strVersion));
  }
  std::cout << "C-ares version: " << strVersion;
}