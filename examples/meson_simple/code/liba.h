#ifndef LIBA_H_
#define LIBA_H_ (1)

#include <stdio.h>

#include <string>

// Export the symbol when building the Windows DLL so MSVC emits an import
// library (a_shared.lib). Empty for the static build, for consumers, and on
// non-Windows platforms, where it is not needed.
#if defined(_WIN32) && defined(LIBA_SHARED_BUILD)
#define LIBA_API __declspec(dllexport)
#else
#define LIBA_API
#endif

LIBA_API std::string hello_liba(void);

#endif
