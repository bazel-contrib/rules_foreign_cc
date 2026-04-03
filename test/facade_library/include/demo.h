#ifndef RFCC_FACADE_LIBRARY_DEMO_H_
#define RFCC_FACADE_LIBRARY_DEMO_H_

#if defined(_WIN32)
#if defined(DEMO_SHARED_EXPORTS)
#define DEMO_API __declspec(dllexport)
#elif defined(DEMO_SHARED_IMPORTS)
#define DEMO_API __declspec(dllimport)
#else
#define DEMO_API
#endif
#else
#define DEMO_API
#endif

DEMO_API int demo_value(void);

#endif
