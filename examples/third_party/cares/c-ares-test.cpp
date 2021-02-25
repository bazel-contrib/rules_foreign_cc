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