# Output Groups Example

This example demonstrates how to use output groups with rules_foreign_cc to access different build outputs beyond the default targets.

## What this example shows

1. **Complete install tree access** - Using the `gen_dir` output group to get everything the build produces
2. **Specific file access** - Using output groups named after file basenames to access individual outputs
3. **Build logs access** - Using the `CMake_logs` output group to access build scripts and logs
4. **Packaging preparation** - Examples showing how to prepare outputs for packaging with rules_pkg
5. **Platform-specific handling** - Using select() with output groups for different platforms

## Build and test

```bash
# Build the cmake project
bazel build //examples/cmake_output_groups:example_project

# Access the complete install tree
bazel build //examples/cmake_output_groups:complete_install

# Access specific outputs
bazel build //examples/cmake_output_groups:static_library
bazel build //examples/cmake_output_groups:executable_tool

# Access build logs
bazel build //examples/cmake_output_groups:build_logs

# Test the executable
bazel build //examples/cmake_output_groups:test_executable
```

## Inspect the outputs

You can examine what's in each output group:

```bash
# See the complete install tree structure
ls -la bazel-bin/examples/cmake_output_groups/complete_install/

# See individual outputs
ls -la bazel-bin/examples/cmake_output_groups/static_library/
ls -la bazel-bin/examples/cmake_output_groups/executable_tool/

# See build logs
ls -la bazel-bin/examples/cmake_output_groups/build_logs/
```

## Output groups provided

- `gen_dir` - The complete install directory tree
- `libexample_lib.a` (Linux/macOS) or `example_lib.lib` (Windows) - The static library
- `example_tool` (Linux/macOS) or `example_tool.exe` (Windows) - The executable
- `CMake_logs` - Build scripts and log files

## Using with rules_pkg

The BUILD.bazel file includes commented examples showing how to use these output groups with rules_pkg to create distribution packages. Uncomment those sections if you have rules_pkg available in your workspace.

## Key concepts

1. **The `gen_dir` output group** contains the entire install tree as it would be created by running cmake install natively
2. **Individual file output groups** are named after the file's basename and contain just that specific file
3. **Logs output groups** follow the pattern `{RuleName}_logs` and contain build artifacts useful for debugging
4. **Platform handling** can be done using select() statements with output groups
5. **Output groups work seamlessly** with other Bazel rules like pkg_tar, genrule, etc.