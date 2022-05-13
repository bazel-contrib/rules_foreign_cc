""" Rule for building CMake from sources. """

load("//foreign_cc:defs.bzl", "configure_make")

def cmake_tool(name, srcs, **kwargs):
    tags = ["manual"] + kwargs.pop("tags", [])

    parallelism = 16
    conf_opts = ["--parallel=%d" % parallelism]
    make_opts = ["-j%d" % parallelism]

    configure_make(
        name = "{}.build".format(name),
        configure_command = "bootstrap",
        configure_options = conf_opts + ["--", "-DCMAKE_MAKE_PROGRAM=$$MAKE$$"],
        # On macOS at least -DDEBUG gets set for a fastbuild
        copts = ["-UDEBUG"],
        args = make_opts,
        lib_source = srcs,
        out_binaries = select({
            "@platforms//os:windows": ["cmake.exe"],
            "//conditions:default": ["cmake"],
        }),
        out_static_libs = [],
        out_shared_libs = [],
        tags = tags,
        **kwargs
    )

    native.filegroup(
        name = name,
        srcs = ["{}.build".format(name)],
        output_group = "gen_dir",
        tags = tags,
    )
