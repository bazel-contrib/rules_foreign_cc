# Output Groups

Rules Foreign CC provides several output groups that allow you to access different parts of the build output beyond the default outputs. This is particularly useful when you need to package or process the complete install tree or specific build artifacts.

## Available Output Groups

### `gen_dir`

The `gen_dir` output group contains the complete install directory tree as it would be created by using the native build tool. This is the most important output group for extracting the entire build result.

**Use cases:**
- Packaging the complete install tree using `rules_pkg`
- Accessing all build outputs including documentation, examples, and other files
- Creating custom deployment packages

### Individual Output Files

Each output file produced by the build is available as a separate output group using the file's basename as the group name.

**Examples:**
- `libexample.a` - Static library
- `example.exe` or `example` - Executable binary
- `libexample.so` - Shared library

### Build Logs

A logs output group is created for each rule type, containing build scripts and log files:

- `CMake_logs` - For cmake rules
- `Make_logs` - For make rules  
- `Ninja_logs` - For ninja rules
- `Meson_logs` - For meson rules
- `Configure_logs` - For configure_make rules
- `BoostBuild_logs` - For boost_build rules

## Basic Usage

To access an output group, use the `output_group` attribute in a `filegroup` rule:

```starlark
load("@rules_foreign_cc//foreign_cc:defs.bzl", "cmake")

cmake(
    name = "mylib",
    lib_source = ":srcs",
    out_static_libs = ["libmylib.a"],
)

# Access the complete install directory
filegroup(
    name = "mylib_install",
    srcs = [":mylib"],
    output_group = "gen_dir",
)

# Access a specific output file
filegroup(
    name = "mylib_static",
    srcs = [":mylib"],
    output_group = "libmylib.a",
)

# Access build logs
filegroup(
    name = "mylib_logs",
    srcs = [":mylib"],
    output_group = "CMake_logs",
)
```

## Packaging with rules_pkg

Here's a complete example showing how to use output groups with `rules_pkg` to create distribution packages:

```starlark
load("@rules_foreign_cc//foreign_cc:defs.bzl", "cmake")
load("@rules_pkg//pkg:pkg.bzl", "pkg_tar")

cmake(
    name = "example_lib",
    lib_source = ":sources",
    out_static_libs = ["libexample.a"],
    out_binaries = ["example_tool"],
)

# Extract the complete install tree
filegroup(
    name = "example_install_tree",
    srcs = [":example_lib"],
    output_group = "gen_dir",
)

# Create a tar package with the complete install
pkg_tar(
    name = "example_package",
    srcs = [":example_install_tree"],
    package_dir = "/usr/local",
    strip_prefix = "example_lib",
)

# Create separate packages for different components
filegroup(
    name = "example_binary",
    srcs = [":example_lib"],
    output_group = "example_tool",
)

pkg_tar(
    name = "example_bin_package",
    srcs = [":example_binary"],
    package_dir = "/usr/bin",
)
```

## Advanced Usage

### Conditional Output Groups

You can use `select()` statements with output groups for platform-specific outputs:

```starlark
filegroup(
    name = "platform_binary",
    srcs = [":mylib"],
    output_group = select({
        "@platforms//os:windows": "mylib.exe",
        "//conditions:default": "mylib",
    }),
)
```

### Multiple Output Groups

To access multiple output groups, create separate filegroup targets:

```starlark
filegroup(
    name = "all_libs",
    srcs = [
        ":static_libs",
        ":shared_libs",
        ":headers",
    ],
)

filegroup(
    name = "static_libs",
    srcs = [":mylib"],
    output_group = "libmylib.a",
)

filegroup(
    name = "shared_libs", 
    srcs = [":mylib"],
    output_group = "libmylib.so",
)

filegroup(
    name = "headers",
    srcs = [":mylib"],
    output_group = "gen_dir",
)
```

## Tips and Best Practices

1. **Use `gen_dir` for complete packaging** - When you need everything the build produces, use the `gen_dir` output group.

2. **Inspect available output groups** - Use `bazel query` to see what output groups are available:
   ```bash
   bazel query --output=build //path/to:target
   ```

3. **Combine with rules_pkg** - Output groups work excellently with packaging rules to create distribution artifacts.

4. **Platform-specific handling** - Use `select()` statements when dealing with platform-specific file extensions or names.

5. **Access logs for debugging** - The logs output groups are useful for debugging build issues or understanding what the build system is doing.