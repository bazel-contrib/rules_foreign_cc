# Copyright 2018 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

def _cc_configure_make_impl(ctx):
    out_includes = ctx.actions.declare_directory(ctx.attr.name + "-includes.h")
    out_lib = ctx.actions.declare_file("{}.a".format(ctx.attr.name))
    outputs = [out_includes, out_lib]

    cpp_fragment = ctx.fragments.cpp
    compiler_options = []  # cpp_fragment.compiler_options(ctx.features)
    c_options = compiler_options + cpp_fragment.c_options
    cxx_options = compiler_options + cpp_fragment.cxx_options(ctx.features)

    CFLAGS = "\"{}\"".format(" ".join(c_options))
    CXXFLAGS = "\"{}\"".format(" ".join(cxx_options))

    # Run ./configure && make from a temporary directory, and install into another temporary directory.
    # Finally, copy the results into the directory artifact declared in out_includes.
    ctx.actions.run_shell(
        mnemonic = "ConfigureMake",
        inputs = ctx.attr.src.files,
        outputs = outputs,
        command = "\n".join([
            "set -e",
            "P=$(pwd)",
            "tmpdir=$(mktemp -d)",
            "tmpinstalldir=$(mktemp -d)",
            "trap \"{ rm -rf $tmpdir $tmpinstalldir; }\" EXIT",
            "pushd $tmpdir",
            "CFLAGS={} CXXFLAGS={} $P/{}/configure --prefix=$tmpinstalldir {}".format(
                CFLAGS,
                CXXFLAGS,
                ctx.attr.src.label.workspace_root,
                " ".join(ctx.attr.configure_flags),
            ),
            "CFLAGS={} CXXFLAGS={} make install".format(CFLAGS, CXXFLAGS),
            "popd",
            "cp $tmpinstalldir/{} {}".format(ctx.attr.out_lib_path, out_lib.path),
            "cp -R $tmpinstalldir/include/ {}".format(out_includes.path),
        ]),
        execution_requirements = {"block-network": ""},
    )
    return [
        DefaultInfo(files = depset(direct = outputs)),
        OutputGroupInfo(
            headers = depset([out_includes]),
            libfile = depset([out_lib]),
        ),
    ]

_cc_configure_make_rule = rule(
    attrs = {
        "configure_flags": attr.string_list(),
        "src": attr.label(mandatory = True),
        "out_lib_path": attr.string(mandatory = True),
    },
    fragments = ["cpp"],
    output_to_genfiles = True,
    implementation = _cc_configure_make_impl,
)

def cc_configure_make(name, configure_flags, src, out_lib_path):
    name_cmr = "_{}_cc_configure_make_rule".format(name)
    _cc_configure_make_rule(
        name = name_cmr,
        configure_flags = configure_flags,
        src = src,
        out_lib_path = out_lib_path,
    )

    name_libfile_fg = "_{}_libfile_fg".format(name)
    native.filegroup(
        name = name_libfile_fg,
        srcs = [name_cmr],
        output_group = "libfile",
    )

    name_libfile_import = "_{}_libfile_import".format(name)
    native.cc_import(
        name = name_libfile_import,
        static_library = name_libfile_fg,
    )

    name_headers_fg = "_{}_headers_fg".format(name)
    native.filegroup(
        name = name_headers_fg,
        srcs = [name_cmr],
        output_group = "headers",
    )

    native.cc_library(
        name = name,
        hdrs = [name_headers_fg],
        includes = [name_cmr + "-includes.h"],
        deps = [name_libfile_import],
    )
