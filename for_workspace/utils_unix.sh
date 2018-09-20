#!/usr/bin/env bash

# default placeholder value
REPLACE_VALUE='BAZEL_GEN_ROOT'
export BUILD_PWD=$(pwd)

# Echo variables in the format
# var1_name="var1_value"
# ...
# vark_name="vark_value"
#
# arguments: the names of the variables
function echo_vars() {
  for arg in "$@"
  do
    echo_var "$arg"
  done
}

# Echo variable in the format var_name="var_value"
# $1 the name of the variable
function echo_var() {
  local name="$1"
  local value=${!name}
  echo "$name: \"${value}\""
}

# Wrap the function execution in the echo lines:
# --- START $1
# (anything printed by $2)
# --- END $1
# $1 parameter to be printed next to start/end text
# $2 function to call in between START and END
function wrap() {
  echo "--- START $1:"
  $2
  echo "--- END $1"
}

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
    find -L $1 -type f \( -name "*.pc" -or -name "*.la" \) \
    -exec sed -i 's@'"$2"'@'"$3"'@g' {} ';'
  fi
}

# copies contents of the directory to target directory
# (create the target directory if needed)
# $1 source directory, immediate children of which are copied
# $2 target directory
function copy_dir_contents_to_dir() {
  local children=$(find $1 -maxdepth 1 -mindepth 1)
  local target="$2"
  mkdir -p ${target}
  for child in $children; do
    cp -R $child ${target}
  done
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
    cp $1 ${target}
  else
    echo "Can not copy $1"
  fi
}

# Copy all files from source directory to target directory
# (create the target directory if needed),
# and add target paths on to path
# $1 source directory
# $2 target directory
function copy_and_add_to_path() {
  copy_to_dir $1 $2
  path $2/bin
  path $2
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