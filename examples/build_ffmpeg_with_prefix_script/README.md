```sh
bazel build @ffmpeg//:library
LD_LIBRARY_PATH=$(find -L bazel-out -type d -path "**/copy_*/*/lib" | sed -e ':a;N;$!ba;s|\n|:|g') firefox
```
