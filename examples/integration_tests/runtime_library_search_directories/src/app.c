#include <stdio.h>
#include <string.h>

#include "runtime_chain.h"

#ifndef RUNTIME_TEST_FAMILY
#define RUNTIME_TEST_FAMILY "unknown"
#endif

int main(void) {
    const char* actual = middle_marker();
    const char* expected = RUNTIME_TEST_FAMILY
        ": expected libmiddle loaded through rpath -> expected libleaf loaded "
        "through rpath";

    puts(actual);
    if (strcmp(actual, expected) != 0) {
        fprintf(stderr, "expected: %s\n", expected);
        fprintf(stderr, "actual:   %s\n", actual);
        return 1;
    }
    return 0;
}
