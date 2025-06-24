"""A module for bringing in transitive dependencies of rules_jvm_external"""

# note that the following line is what is minimally required from protobuf for the java rules
# consider using the protobuf_deps() public API from @com_google_protobuf//:protobuf_deps.bzl
load("@com_google_protobuf//bazel/private:proto_bazel_features.bzl", "proto_bazel_features")  # buildifier: disable=bzl-visibility
load("@rules_jvm_external//:defs.bzl", "maven_install")

def deps_jvm_external():
    maven_install(
        artifacts = [
            "com.android.support.constraint:constraint-layout:aar:1.1.2",
            "com.android.support:appcompat-v7:aar:26.1.0",
        ],
        repositories = [
            "https://jcenter.bintray.com/",
            "https://maven.google.com",
            "https://repo1.maven.org/maven2",
        ],
    )
    proto_bazel_features(name = "proto_bazel_features")
