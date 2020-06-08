load(":cmake_text_tests.bzl", "cmake_script_test_suite")
load(":convert_shell_script_test.bzl", "shell_script_conversion_suite")
load(":utils_test.bzl", "utils_test_suite")
load(":shell_script_helper_test_rule.bzl", "shell_script_helper_test_rule")
load("@bazel_skylib//rules:diff_test.bzl", "diff_test")
load(":symlink_contents_to_dir_test_rule.bzl", "symlink_contents_to_dir_test_rule")

cmake_script_test_suite()

shell_script_conversion_suite()

utils_test_suite()

shell_script_helper_test_rule(
    name = "shell_script_inner_fun",
    out = "inner_fun_text.txt",
    script = ["##symlink_contents_to_dir## $$SOURCE_DIR$$ $$TARGET_DIR$$"],
)

result_file = select({
    "@bazel_tools//src/conditions:darwin": "expected/inner_fun_text_osx.txt",
    "//conditions:default": "expected/inner_fun_text.txt",
})

result_file_symlink_dirs = select({
    "@bazel_tools//src/conditions:darwin": "expected/out_symlinked_dirs_osx.txt",
    "//conditions:default": "expected/out_symlinked_dirs.txt",
})

diff_test(
    name = "shell_script_inner_fun_test",
    file1 = ":shell_script_inner_fun",
    file2 = result_file,
)

filegroup(
    name = "dir1_fg",
    srcs = glob(["dir1/**"], exclude_directories = 0),
)

filegroup(
    name = "dir2_fg",
    srcs = glob(["dir2/**"], exclude_directories = 0),
)

symlink_contents_to_dir_test_rule(
    name = "symlink_dirs",
    out = "out_symlinked_dirs.txt",
    dir1 = ":dir1_fg",
    dir2 = ":dir2_fg",
)

diff_test(
    name = "shell_method_symlink_contents_to_dir_test",
    file1 = result_file_symlink_dirs,
    file2 = ":symlink_dirs",
)
