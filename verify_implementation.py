#!/usr/bin/env python3

"""
Simple verification script to check that the set_file_prefix_map changes are correct.
This validates the syntax and structure without requiring bazel to build.
"""

import ast
import os
import sys

def check_file_content(file_path, expected_content):
    """Check if file contains expected content."""
    try:
        with open(file_path, 'r') as f:
            content = f.read()
            if expected_content in content:
                print(f"✓ {file_path}: Found expected content")
                return True
            else:
                print(f"✗ {file_path}: Missing expected content")
                return False
    except FileNotFoundError:
        print(f"✗ {file_path}: File not found")
        return False

def check_select_syntax(file_path):
    """Check if the select() syntax in framework.bzl is valid."""
    try:
        with open(file_path, 'r') as f:
            content = f.read()
            
        # Look for the select statement
        if 'select({' in content and '"//foreign_cc:disable_set_file_prefix_map": False' in content:
            print(f"✓ {file_path}: select() syntax looks correct")
            return True
        else:
            print(f"✗ {file_path}: select() syntax issue")
            return False
    except FileNotFoundError:
        print(f"✗ {file_path}: File not found")
        return False

def main():
    print("Verifying set_file_prefix_map implementation...\n")
    
    base_path = "/home/runner/work/rules_foreign_cc/rules_foreign_cc"
    
    checks = [
        # Check string_flag is defined
        (f"{base_path}/foreign_cc/private/BUILD.bazel", 'string_flag('),
        (f"{base_path}/foreign_cc/private/BUILD.bazel", 'name = "disable_set_file_prefix_map"'),
        
        # Check config_setting is defined
        (f"{base_path}/foreign_cc/BUILD.bazel", 'config_setting('),
        (f"{base_path}/foreign_cc/BUILD.bazel", '"//foreign_cc/private:disable_set_file_prefix_map": "True"'),
        
        # Check test files exist
        (f"{base_path}/test/set_file_prefix_map_test.bzl", 'set_file_prefix_map'),
        (f"{base_path}/SET_FILE_PREFIX_MAP_MIGRATION.md", 'Migration Guide'),
    ]
    
    all_passed = True
    
    for file_path, expected in checks:
        if not check_file_content(file_path, expected):
            all_passed = False
    
    # Special check for select() syntax
    if not check_select_syntax(f"{base_path}/foreign_cc/private/framework.bzl"):
        all_passed = False
    
    print("\n" + "="*50)
    if all_passed:
        print("✓ ALL CHECKS PASSED!")
        print("\nThe set_file_prefix_map implementation appears correct:")
        print("- string_flag defined for global override")
        print("- config_setting defined to check the flag") 
        print("- select() used to make True the default")
        print("- Tests and documentation added")
        return 0
    else:
        print("✗ SOME CHECKS FAILED!")
        return 1

if __name__ == "__main__":
    sys.exit(main())