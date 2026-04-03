#ifndef RFCC_FACADE_STATIC_LIBRARY_COMBO_H_
#define RFCC_FACADE_STATIC_LIBRARY_COMBO_H_

#if defined(_WIN32) && defined(COMBO_SHARED_EXPORTS)
#define COMBO_SHARED_API __declspec(dllexport)
#else
#define COMBO_SHARED_API
#endif

COMBO_SHARED_API int combo_value(void);

#endif
