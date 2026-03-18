#ifndef FOO
#error FOO is not defined
#endif

#define XSTR(x) STR(x)
#define STR(x) #x
#pragma message("The value of __TIME__: " XSTR(__TIME__))

#define STATIC_ASSERT(condition, name) \
    typedef char assert_failed_##name[(condition) ? 1 : -1];

// Verify __TIME__ was replaced with "redacted" by the build system.
// A real __TIME__ is always "HH:MM:SS" starting with a digit; "redacted" starts
// with 'r'.
#if defined(_MSC_VER)
// MSVC does not honor overriding __TIME__ via compiler definitions (you have to
// use a forced include for that, and the default rules_cc toolchain doesn't do
// that)
void foo() {}
#else
void foo() { STATIC_ASSERT(__TIME__[0] == 'r', time_must_be_redacted); }
#endif

// Should return "redacted"
const char* getBuildTime(void) { return __TIME__; }
