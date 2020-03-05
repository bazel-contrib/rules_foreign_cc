load(":cmake_text_tests.bzl", "cmake_script_test_suite")
load(":convert_shell_script_test.bzl", "shell_script_conversion_suite")
load(":utils_test.bzl", "utils_test_suite")
load(":shell_script_helper_test_rule.bzl", "shell_script_helper_test_rule")
load("@bazel_skylib//rules:diff_test.bzl", "diff_test")

cmake_script_test_suite()

shell_script_conversion_suite()

utils_test_suite()

shell_script_helper_test_rule(
    name = "shell_script_inner_fun",
    out = "inner_fun_text.txt",
    script = ["##symlink_contents_to_dir## $$SOURCE_DIR$$ $$TARGET_DIR$$"],
)

diff_test(
    name = "shell_script_inner_fun_test",
    file1 = ":shell_script_inner_fun",
    file2 = "expected/inner_fun_text.txt",
)
