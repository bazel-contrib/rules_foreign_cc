load("@rules_foreign_cc//tools/build_defs:make.bzl", "make")

make(
    name = "luajit",
    lib_source = "@luajit//:all",
    # Taken from https://github.com/envoyproxy/envoy/blob/master/bazel/foreign_cc/luajit.patch
    # However, only a pair of variables are taken to make the luajit build work.
    # Probably you want to explore other variables more exactly;
    # For instance, CFLAGS are not copied into TARGET_FLAGS
    make_env_vars = {
        "TARGET_CFLAGS": "-fno-function-sections -fno-data-sections",
        "TARGET_LDFLAGS": "-fno-function-sections -fno-data-sections",
        "LSAN_OPTIONS": "exitcode=0",
    },
    static_libraries = ["libluajit-5.1.a"],
)
