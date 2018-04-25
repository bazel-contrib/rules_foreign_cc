# These repositories are used in the BUILD files in examples/, which are also used in CI.

new_http_archive(
    name = "libevent",
    build_file_content = """filegroup(name = "all", srcs = glob(["**"]), visibility = ["//visibility:public"])""",
    strip_prefix = "libevent-2.1.8-stable",
    urls = ["https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz"],
)
