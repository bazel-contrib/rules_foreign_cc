#!/bin/bash

# Test script to verify set_file_prefix_map functionality
# This script demonstrates how to use the new global flag

echo "Testing set_file_prefix_map default behavior..."

# Test 1: Default behavior (should have set_file_prefix_map = True)
echo "1. Building with default settings (set_file_prefix_map should be True)..."
# bazel build //test:test_default_file_prefix_map 

# Test 2: Global override to disable set_file_prefix_map
echo "2. Building with global disable flag..."
# bazel build --//foreign_cc/private:disable_set_file_prefix_map=True //test:test_default_file_prefix_map

# Test 3: Explicit local override should still work
echo "3. Building with explicit local disable..."  
# bazel build //test:test_disabled_file_prefix_map

echo "Usage examples:"
echo "  # Use new default (set_file_prefix_map=True):"
echo "  bazel build //your:target"
echo ""
echo "  # Globally disable for compiler compatibility:"
echo "  bazel build --//foreign_cc/private:disable_set_file_prefix_map=True //your:target"
echo ""
echo "  # Or disable via .bazelrc:"
echo "  echo 'build --//foreign_cc/private:disable_set_file_prefix_map=True' >> .bazelrc"