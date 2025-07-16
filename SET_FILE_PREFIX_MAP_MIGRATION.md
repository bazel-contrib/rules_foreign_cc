# set_file_prefix_map Changes

## Summary

The `set_file_prefix_map` attribute now defaults to `True` for all foreign_cc rules (cmake, configure_make, make, etc.), making builds more hermetic by default.

## What Changed

Previously, `set_file_prefix_map` defaulted to `False`. Now it defaults to `True`, which means the `-ffile-prefix-map=$EXT_BUILD_ROOT=.` compiler flag is automatically added to C and C++ compile commands. This removes absolute sandbox paths from debug symbols, making builds more reproducible and hermetic.

## Migration Guide

### If your builds work fine
No action needed. Your builds will now be more hermetic by default.

### If your compiler doesn't support -ffile-prefix-map

You have several options:

1. **Global disable via command line:**
   ```bash
   bazel build --//foreign_cc/private:disable_set_file_prefix_map=True //your:target
   ```

2. **Global disable via .bazelrc:**
   ```bash
   echo 'build --//foreign_cc/private:disable_set_file_prefix_map=True' >> .bazelrc
   ```

3. **Disable per target:**
   ```bzl
   cmake(
       name = "my_lib",
       lib_source = ":srcs",
       set_file_prefix_map = False,  # Explicit disable for this target
   )
   ```

## Technical Details

- The flag adds `-ffile-prefix-map=$EXT_BUILD_ROOT=.` to C/C++ compile commands
- This replaces absolute sandbox paths with `.` in debug symbols
- Supported by GCC 8+, Clang 10+, and most modern compilers
- Improves build hermiticity and reproducibility