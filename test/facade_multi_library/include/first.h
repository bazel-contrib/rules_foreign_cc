#ifndef RFCC_FACADE_MULTI_LIBRARY_FIRST_H_
#define RFCC_FACADE_MULTI_LIBRARY_FIRST_H_

#if defined(_WIN32)
#if defined(FIRST_SHARED_EXPORTS)
#define FIRST_API __declspec(dllexport)
#elif defined(FIRST_SHARED_IMPORTS)
#define FIRST_API __declspec(dllimport)
#else
#define FIRST_API
#endif
#else
#define FIRST_API
#endif

FIRST_API int first_value(void);

#endif
