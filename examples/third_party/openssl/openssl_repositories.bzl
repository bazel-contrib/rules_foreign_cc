"""A module defining the third party dependency OpenSSL"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("@rules_foreign_cc//foreign_cc:providers.bzl", "ForeignCcDepsInfo")

_PROXY_BUILD_FILE_CONTENTS = """\
config_setting(
    name = "windows",
    constraint_values = ["@platforms//os:windows"],
    visibility = ["//visibility:public"],
)

alias(
    name = "openssl",
    actual = select({{
        ":windows": "@{repo}//:openssl_msvc",
        "//conditions:default": "@{repo}//:openssl",
    }}),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "gen_dir",
    srcs = [":openssl"],
    output_group = "gen_dir",
    visibility = ["//visibility:public"],
)
"""

def openssl_repositories():
    """A macro for defining openssl and it's dependency repositories"""

    openssl_build_repo = "openssl_lib"
    maybe(
        http_archive,
        name = openssl_build_repo,
        build_file = Label("//openssl:BUILD.openssl.bazel"),
        sha256 = "5c9ca8774bd7b03e5784f26ae9e9e6d749c9da2438545077e6b3d755a06595d9",
        strip_prefix = "openssl-1.1.1h",
        urls = [
            "https://www.openssl.org/source/openssl-1.1.1h.tar.gz",
            "https://github.com/openssl/openssl/archive/OpenSSL_1_1_1h.tar.gz",
        ],
    )

    # A proxy repository who's only job is to provide an alias for easy consumption
    # of the openssl build under the right configuration.
    maybe(
        native.new_local_repository,
        name = "openssl",
        path = ".",
        build_file_content = _PROXY_BUILD_FILE_CONTENTS.format(
            repo = openssl_build_repo,
        ),
    )

    # The windows build requires a native perl installation
    maybe(
        http_archive,
        name = "strawberry_perl",
        build_file = Label("//openssl:BUILD.strawberry_perl.bazel"),
        sha256 = "692646105b0f5e058198a852dc52a48f1cebcaf676d63bbdeae12f4eaee9bf5c",
        strip_prefix = "perl",
        urls = [
            "https://strawberryperl.com/download/5.32.1.1/strawberry-perl-5.32.1.1-64bit-portable.zip",
        ],
    )

    # The VC build requires NASM
    maybe(
        http_archive,
        name = "nasm",
        build_file = Label("//openssl:BUILD.nasm.bazel"),
        sha256 = "f5c93c146f52b4f1664fa3ce6579f961a910e869ab0dae431bd871bdd2584ef2",
        strip_prefix = "nasm-2.15.05",
        urls = [
            "https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/win64/nasm-2.15.05-win64.zip",
        ],
    )

def _env_transition_impl(settings, attrs):
    _ignore = (settings)
    return {"//command_line_option:host_platform": str(attrs.platform)}

_env_transition = transition(
    implementation = _env_transition_impl,
    inputs = [],
    outputs = ["//command_line_option:host_platform"],
)

def _msvc_openssl_impl(ctx):
    target = ctx.attr.target[0]

    # Return the providers from the transitioned foreign_cc target
    return [
        target[DefaultInfo],
        target[CcInfo],
        target[ForeignCcDepsInfo],
        target[OutputGroupInfo],
    ]

host_transitioned_foreign_cc_target = rule(
    doc = "A rule for building a `rules_foreign_cc` target on an msvc windows platform",
    implementation = _msvc_openssl_impl,
    attrs = {
        "platform": attr.label(
            doc = "The platform in question to build for.",
            mandatory = True,
        ),
        "target": attr.label(
            doc = "The foreign_cc target to transition for.",
            cfg = _env_transition,
            providers = [ForeignCcDepsInfo],
            mandatory = True,
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
    incompatible_use_toolchain_transition = True,
)
