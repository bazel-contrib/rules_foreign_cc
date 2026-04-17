#ifndef RFCC_FACADE_MULTI_LIBRARY_SECOND_H_
#define RFCC_FACADE_MULTI_LIBRARY_SECOND_H_

#if defined(_WIN32)
#if defined(SECOND_SHARED_EXPORTS)
#define SECOND_API __declspec(dllexport)
#elif defined(SECOND_SHARED_IMPORTS)
#define SECOND_API __declspec(dllimport)
#else
#define SECOND_API
#endif
#else
#define SECOND_API
#endif

SECOND_API int second_value(void);

#endif
