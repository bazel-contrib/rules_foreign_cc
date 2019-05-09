#include <stdio.h>
#include "simple.h"
#include "builtWithBazel.h"

void simpleFun(void) {
  printf("simpleFun: %s", bazelSays());
}