#ifndef TEST_FACADE_SHARED_LIBRARY_INCLUDE_LEAF_DATA_H_
#define TEST_FACADE_SHARED_LIBRARY_INCLUDE_LEAF_DATA_H_

#if defined(_WIN32) && defined(LEAF_DATA_SHARED_EXPORTS)
#define LEAF_DATA_API __declspec(dllexport)
#elif defined(_WIN32)
#define LEAF_DATA_API __declspec(dllimport)
#else
#define LEAF_DATA_API
#endif

LEAF_DATA_API int leaf_data_value(void);

#endif
