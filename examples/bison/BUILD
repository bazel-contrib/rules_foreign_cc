load("@rules_foreign_cc//tools/build_defs:configure.bzl", "configure_make")

# I tested and this builds for me on MAC and Linux, did not check Windows thouigh
configure_make(
    name = "bison",
    binaries = [
        "bison",
        "yacc",
    ],
    lib_source = "@bison//:all",
    static_libraries = ["liby.a"],
)
