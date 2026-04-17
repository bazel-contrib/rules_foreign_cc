#ifndef RFCC_FACADE_CHAIN_LEAF_H_
#define RFCC_FACADE_CHAIN_LEAF_H_

#if defined(_WIN32)
#if defined(LEAF_SHARED_EXPORTS)
#define LEAF_API __declspec(dllexport)
#elif defined(LEAF_SHARED_IMPORTS)
#define LEAF_API __declspec(dllimport)
#else
#define LEAF_API
#endif
#else
#define LEAF_API
#endif

LEAF_API int leaf_value(void);

#endif
