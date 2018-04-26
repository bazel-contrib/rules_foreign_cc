# rules_foreign_cc

Rules for building projects using foreign build systems inside Bazel projects.

* Experimental - API will most definitely change.
* This is not an officially supported Google product
(meaning, support and/or new releases may be limited.)

## ./configure && make

**NOTE**: this requires building Bazel from head after https://github.com/bazelbuild/bazel/commit/060b1624e4d64dbdbeb375f9a55a3da9bd055a54

Example:

* In `WORKSPACE`, we use a `new_http_archive` to download tarballs with the libraries we use.
* In `BUILD`, we instantiate a `cc_configure_make_library` macro which behaves similarly to a `cc_library`, which can then be used in a C++ rule (`cc_binary` in this case).

In `WORKSPACE`, put

```python
new_http_archive(
    name = "libevent",
    build_file_content = """filegroup(name = "all", srcs = glob(["**"]), visibility = ["//visibility:public"])""",
    strip_prefix = "libevent-2.1.8-stable",
    urls = ["https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz"],
)
```

and in `BUILD`, put

```python
cc_configure_make(
    name = "libevent",
    src = "@libevent//:all",
    configure_flags = [
        "--enable-shared=no",
        "--disable-libevent-regress",
        "--disable-openssl",
    ],
    out_lib_path = "lib/libevent.a",
)

cc_binary(
    name = "libevent_echosrv1",
    srcs = ["libevent_echosrv1.c"],
    deps = [":libevent"],
)
```

then build as usual:

```bash
$ devbazel build //:libevent_echosrv1
```
