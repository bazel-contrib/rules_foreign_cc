#!/usr/bin/env bash

# default placeholder value
REPLACE_VALUE='BAZEL_GEN_ROOT'
export BUILD_PWD=$(pwd)

# Append string to PATH variable
# $1 string to append
function path() {
  export PATH="$1:$PATH"
}

# Replace string in *.pc and *.la files in directory
# $1 directory to search recursively, absolute path
# $2 string to replace
# $3 replace target
function replace_in_files() {
  if [ -d "$1" ]; then
    find -L $1 -print -type f \
     \( -name "*.pc" -or -name "*.la" -or -name "*-config" -or -name "*.cmake" \) \
    -exec sed -i 's@'"$2"'@'"$3"'@g' {} ';'
  fi
}

# copies contents of the directory to target directory
# (create the target directory if needed)
# $1 source directory, immediate children of which are copied
# $2 target directory
function copy_dir_contents_to_dir() {
  cp -L -r --no-target-directory "$1" "$2"
}

# Symlink contents of the directory to target directory
# (create the target directory if needed).
# If file is passed, symlink it into the target directory.
# $1 source directory, immediate children of which are symlinked,
# or file to be symlinked.
# $2 target directory
function symlink_contents_to_dir() {
  local target="$2"
  mkdir -p ${target}
  if [[ -f $1 ]]; then
    symlink_to_dir $1 ${target}
    return 0
  fi
  local children=$(find $1 -maxdepth 1 -mindepth 1)
  for child in $children; do
    symlink_to_dir $child ${target}
  done
}

# Symlink all files from source directory to target directory
# (create the target directory if needed)
# NB symlinks from the source directory are copied
# $1 source directory
# $2 target directory
function symlink_to_dir() {
  local target="$2"
  mkdir -p ${target}

  if [[ -d $1 ]]; then
    ln -s -t ${target} $1
  elif [[ -f $1 ]]; then
    ln -s -t ${target} $1
  elif [[ -L $1 ]]; then
    cp --no-target-directory $1 ${target}
  else
    echo "Can not copy $1"
  fi
}

# replace placeholder with absolute path in all files in a directory
# $1 directory
# $2 absolute path
function define_absolute_paths() {
  replace_in_files $1 $REPLACE_VALUE $2
}

# replace the absolute path with a placeholder value in all files in a directory
# $1 directory
# $2 absolute path to replace
function replace_absolute_paths() {
  replace_in_files $1 $2 $REPLACE_VALUE
}

# function for setting necessary environment variables for the platform
function set_platform_env_vars() {
  # empty for Linux
  return 0
}

function increment_pkg_config_path() {
  local children=$(find $1 -mindepth 1 -name '*.pc')
  # assume there is only one directory with pkg config
  for child in $children; do
    export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$(dirname $child)"
    return
  done
}
