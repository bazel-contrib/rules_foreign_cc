#include "test/facade_shared_library_conflicts/native_leaf.h"

int native_root(void) { return native_leaf(); }
