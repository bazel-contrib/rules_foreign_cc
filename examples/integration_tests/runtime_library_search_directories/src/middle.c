#include <stdio.h>

#include "runtime_chain.h"

#ifndef RUNTIME_TEST_FAMILY
#define RUNTIME_TEST_FAMILY "unknown"
#endif

const char* middle_marker(void) {
    static char marker[256];

    snprintf(marker, sizeof(marker),
             "%s: expected libmiddle loaded through rpath -> %s",
             RUNTIME_TEST_FAMILY, leaf_marker());
    return marker;
}
