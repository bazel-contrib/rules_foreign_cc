#include <stdio.h>
#include "simple.h"
#include "builtWithBazel.h"
#include "builtWithBazel2.h"

void simpleFun(void) {
  printf("simpleFun:\n%s\n%s", bazelSays(), bazelSays2());
}