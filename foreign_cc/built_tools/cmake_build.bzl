""" Rule for building CMake from sources. """

load("//foreign_cc:defs.bzl", "ninja")

def cmake_tool(name, srcs, **kwargs):
    tags = ["manual"] + kwargs.pop("tags", [])

    ninja(
        name = "{}.build".format(name),
        env = {
            "MAKE": "$(NINJA)",
        },
        tool_prefix = "$$EXT_BUILD_ROOT$$/external/cmake_src/bootstrap --generator=Ninja --prefix=$$INSTALLDIR -- -DCMAKE_MAKE_PROGRAM=$$MAKE && ",
        # On macOS, at least, -DDEBUG gets set for a fastbuild
        copts = ["-UDEBUG", "-std=c++17"],  # CMake needs the <filesystem> header so select an appropriate c++ standard to make this available
        directory = "$BUILD_TMPDIR",
        lib_source = srcs,
        out_binaries = select({
            "@platforms//os:windows": ["cmake.exe"],
            "//conditions:default": ["cmake"],
        }),
        out_static_libs = [],
        out_shared_libs = [],
        tags = tags,
        targets = ["all", "install"],
        deps = kwargs.pop("deps", []),
        toolchains = kwargs.pop("toolchains", []) + [str(Label("//toolchains:current_ninja_toolchain"))],
        **kwargs
    )

    native.filegroup(
        name = name,
        srcs = ["{}.build".format(name)],
        output_group = "gen_dir",
        tags = tags,
    )
