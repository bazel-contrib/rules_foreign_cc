"""Native cc_static_library indirection for Bazel 7 experimental probing."""

def cc_static_library(**kwargs):
    native.cc_static_library(**kwargs)
