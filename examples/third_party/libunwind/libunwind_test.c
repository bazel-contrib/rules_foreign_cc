#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define UNW_LOCAL_ONLY 1
#include "libunwind.h"

#ifndef __has_attribute
#define __has_attribute(x) 0
#endif

#if defined(__GNUC__) || __has_attribute(noinline)
#define NOINLINE __attribute__((noinline))
#elif defined(_MSC_VER)
#define NOINLINE __declspec(noinline)
#else
#define NOINLINE
#endif

NOINLINE void bar() {
  unw_context_t context;
  unw_cursor_t cursor;
  unw_word_t ip, sp, off;
  char proc_name[256];
  if (unw_getcontext(&context)) {
    return;
  }
  if (unw_init_local(&cursor, &context)) {
    return;
  }
  for (;;) {
    if (unw_step(&cursor) <= 0) {
      break;
    }
    ip = 0;
    if (unw_get_reg(&cursor, UNW_REG_IP, &ip)) {
      ip = 0;
    }
    sp = 0;
    if (unw_get_reg(&cursor, UNW_REG_SP, &sp)) {
      sp = 0;
    }
    memset(proc_name, '\0', sizeof(proc_name));
    if (unw_get_proc_name(&cursor, proc_name, sizeof(proc_name) - 1, &off)) {
      proc_name[0] = '\0';
      strcpy(proc_name, "<unknown>");
    }
    fprintf(stdout,
            "proc=%s off=%" PRIdPTR " ip=%" PRIdPTR " sp=%" PRIdPTR "\n",
            proc_name, (uintptr_t)off, (uintptr_t)ip, (uintptr_t)sp);
  }
}

NOINLINE void foo() { bar(); }

int main(int argc, char** argv) {
  foo();
  return 0;
}
