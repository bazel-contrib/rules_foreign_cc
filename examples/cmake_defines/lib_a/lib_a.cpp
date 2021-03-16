#ifndef FOO
#error FOO is not defined
#endif

#define XSTR(x) STR(x)
#define STR(x) #x
#pragma message "The value of __TIME__: " XSTR(__TIME__)

// Should return "redacted"
const char *getBuildTime(void) {
    return __TIME__;
}
