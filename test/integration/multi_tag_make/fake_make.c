// A stand-in for GNU make. It never builds anything: it prints a sentinel and
// fails, so the scenario can assert that rfcc pointed the make toolchain at
// this binary and actually ran it. See ../BUILD.bazel.
//
// Named `make` as a target (so the built file is `make`) because the framework
// symlinks a tool's `path` into $EXT_BUILD_DEPS/bin under that file's basename.
// The make rule invokes the toolchain path directly, so the name is not load
// bearing here, but a real custom tool would need it.
#include <stdio.h>

int main(void) {
  fprintf(stderr, "CUSTOM_MAKE_SENTINEL: root module's make ran\n");
  return 1;
}
