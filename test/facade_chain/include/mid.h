#ifndef RFCC_FACADE_CHAIN_MID_H_
#define RFCC_FACADE_CHAIN_MID_H_

#if defined(_WIN32)
#if defined(MID_SHARED_EXPORTS)
#define MID_API __declspec(dllexport)
#elif defined(MID_SHARED_IMPORTS)
#define MID_API __declspec(dllimport)
#else
#define MID_API
#endif
#else
#define MID_API
#endif

MID_API int mid_value(void);

#endif
