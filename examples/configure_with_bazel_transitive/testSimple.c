#include <stdio.h>
#include "built_with_bazel/detail/builtWithBazel.h"
#include "built_with_bazel_2/detail/builtWithBazel2.h"
#include "simple.h"

int main(int argc, char **argv) {
  printf("Call bazelSays() directly: %s\n", bazelSays());
  printf("Call bazelSays2() directly: %s\n", bazelSays2());
  simpleFun();
  return 0;
}