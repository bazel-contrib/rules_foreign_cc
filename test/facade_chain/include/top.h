#ifndef RFCC_FACADE_CHAIN_TOP_H_
#define RFCC_FACADE_CHAIN_TOP_H_

#if defined(_WIN32)
#if defined(TOP_SHARED_EXPORTS)
#define TOP_API __declspec(dllexport)
#elif defined(TOP_SHARED_IMPORTS)
#define TOP_API __declspec(dllimport)
#else
#define TOP_API
#endif
#else
#define TOP_API
#endif

TOP_API int top_value(void);

#endif
