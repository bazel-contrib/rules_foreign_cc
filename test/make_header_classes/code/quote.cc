#include "precedence.h"

#if HEADER_VALUE != 23
#error "quoted include must prefer the quote directory"
#endif

int quote_header() { return HEADER_VALUE; }
