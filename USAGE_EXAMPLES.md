# Usage Examples for set_file_prefix_map

## Example 1: Default behavior (recommended)
```bzl
load("@rules_foreign_cc//foreign_cc:defs.bzl", "cmake")

cmake(
    name = "my_library",
    lib_source = ":srcs",
    # set_file_prefix_map = True by default (NEW!)
    # Automatically adds -ffile-prefix-map=$EXT_BUILD_ROOT=. to compile commands
)
```

## Example 2: Globally disable for older compilers
```bash
# Via command line
bazel build --//foreign_cc/private:disable_set_file_prefix_map=True //my:target

# Via .bazelrc (recommended for consistent behavior)
echo 'build --//foreign_cc/private:disable_set_file_prefix_map=True' >> .bazelrc
```

## Example 3: Disable per target
```bzl
cmake(
    name = "legacy_library", 
    lib_source = ":srcs",
    set_file_prefix_map = False,  # Explicit override for this target
)
```

## Compiler Compatibility
- **Supported:** GCC 8+, Clang 10+, MSVC 2019+
- **Flag added:** `-ffile-prefix-map=$EXT_BUILD_ROOT=.` 
- **Effect:** Removes absolute sandbox paths from debug symbols
- **Benefit:** More hermetic and reproducible builds