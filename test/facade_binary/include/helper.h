#ifndef RFCC_FACADE_BINARY_HELPER_H_
#define RFCC_FACADE_BINARY_HELPER_H_

#if defined(_WIN32)
#if defined(HELPER_SHARED_EXPORTS)
#define HELPER_API __declspec(dllexport)
#elif defined(HELPER_SHARED_IMPORTS)
#define HELPER_API __declspec(dllimport)
#else
#define HELPER_API
#endif
#else
#define HELPER_API
#endif

HELPER_API int helper_value(void);

#endif
