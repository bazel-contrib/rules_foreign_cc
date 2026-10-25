#include <precedence.h>

#if HEADER_VALUE != 17
#error "angle include must use the ordinary directory"
#endif

int angle_header() { return HEADER_VALUE; }
