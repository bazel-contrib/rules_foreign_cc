#include "nghttp2/nghttp2.h"

#include <iostream>
#include <string.h>

int main(int argc, char* argv[])
{
  nghttp2_info* version = nghttp2_version(0);
  if (strcmp(version -> version_str, "1.32.90") != 0) {
    throw std::runtime_error("Wrong version: " + std::string(version -> version_str));
  }
  std::cout << "nghttp2 version: " << version -> version_str;
}