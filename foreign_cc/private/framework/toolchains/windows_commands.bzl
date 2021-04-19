"""Define windows foreign_cc framework commands. Windows uses Powershell"""

load(":commands.bzl", "FunctionAndCall")

def shebang():
    return """\
#!/usr/bin/env powershell

# Detect platform to identify path separator. If the version of powershell is less than 6, we assume the platform is windows
if ((!(Get-Variable PSVersionTable -Scope Global)) -or ([System.Version]$PSVersionTable.PSVersion -lt [System.Version]"6.0")) {
    $PATH_SEP=";"
} else {
    if ($IsWindows) {
        $PATH_SEP=";"
    } else {
        $PATH_SEP=":"
    }
}
"""

def wrapper_extension():
    return ".ps1"

def pwd():
    return "$pwd"

def echo(text):
    return "echo \"{text}\"".format(text = text)

def export_var(name, value):
    return "$env:{name}={value}".format(name = name, value = value)

def local_var(name, value):
    return "${name}={value}".format(name = name, value = value)

def use_var(name):
    return "$env:" + name

def env():
    return "Get-ChildItem env:"

def path(expression):
    return "$env:PATH = \"{expression}\" + \"$PATH_SEP\" + \"$env:PATH\"".format(expression = expression)

def touch(path):
    return "New-Item -ItemType file -Force -Path " + path + " | Out-Null"

def enable_tracing():
    return "Set-PSDebug -Trace 2"

def disable_tracing():
    return "Set-PSDebug -Trace 0"

def mkdirs(path):
    return "mkdir -Force " + path

def if_else(condition, if_text, else_text):
    return """\
if ( {condition} ) {{
  {if_text}
}} else {{
  {else_text}
}}
""".format(condition = condition, if_text = if_text, else_text = else_text)

# buildifier: disable=function-docstring
def define_function(name, text):
    lines = []
    lines.append("function " + name + " {")
    for line_ in text.splitlines():
        lines.append("    " + line_)
    lines.append("}")
    return "\n".join(lines)

def replace_in_files(dir, from_, to_):
    return FunctionAndCall(
        text = """\
if ( Test-Path -Path "$Args[0]" -PathType Container) {
    Get-ChildItem "$Args[0]" -Recurse -File -FollowSymlink -Include *.pc,*.la,*-config,*.cmake | % { $_ -replace '"$Args[1]"', '"$Args[2]"' }
}
""",
    )

# TODO: Fix access times
def copy_dir_contents_to_dir(source, target):
    return """\
Copy-Item -Path "{source}" -Destination "{destination}"

# $origLastAccessTime = ( Get-ChildItem "{source}" ).LastAccessTime
# $origLastWriteTime = ( Get-ChildItem "{source}" ).LastWriteTime
# Copy-Item -Path "{source}" -Destination "{destination}"
# (Get-ChildItem "{destination}").LastAccessTime = $origLastAccessTime
# (Get-ChildItem "{destination}").LastWriteTime = $origLastWriteTime
""".format(
        source = source,
        destination = target,
    )

def symlink_contents_to_dir(source, target):
    text = """\
Param(
    [Parameter(Mandatory=$false)]
    [string]
    $source,

    [Parameter(Mandatory=$false)]
    [string]
    $target
)
mkdir -Force "$target"
if ( Test-Path -Path "$source" -PathType Leaf ) {
    ##symlink_to_dir## "$source" "$target"
} elseif (Get-ChildItem -Path "$source" | Where-Object { $_.Attributes -match "ReparsePoint" }) {
    $actual = Get-ChildItem -Path "$source"
    ##symlink_contents_to_dir## "$actual" "$target"
} elseif ( Test-Path -Path "$source" -PathType Container ) {
    $children = Get-ChildItem -Path "$source" -Depth 1 -Force
    ForEach-Object -InputObject $children {
        ##symlink_to_dir## "$_" "$target"
    }
}
"""
    return FunctionAndCall(text = text)

def symlink_to_dir(source, target):
    text = """\
Param(
    [Parameter(Mandatory=$false)]
    [string]
    $source,

    [Parameter(Mandatory=$false)]
    [string]
    $target
)
mkdir -Force "$target"
if ( Test-Path -Path "$source" -PathType Leaf ) {
    New-Item -ItemType Symlink -Path "$target" -Target "$source"
} elseif (Get-ChildItem -Path "$source" | Where-Object { $_.Attributes -match "ReparsePoint" }) {
    $actual = Get-ChildItem -Path "$source"
    ##symlink_to_dir## "$actual" "$target"
} elseif ( Test-Path -Path "$source" -PathType Container ) {
    $children = Get-ChildItem -Path "$source" -Depth 1 -Force
    ForEach-Object -InputObject $children {
        ##symlink_to_dir## "$_" "$target"
    }
} else {
    echo "Can not copy $source"
}
"""
    return FunctionAndCall(text = text)

def script_prelude():
    return "Set-StrictMode -Version latest"

def increment_pkg_config_path(source):
    text = """\
$children = Get-ChildItem -Path "$Args[0]" -Depth 1 -Force -Filter "*.pc"
# assume there is only one directory with pkg config
ForEach-Object -InputObject $children {
    $child_parent = Split-Path -Parent -Path "$_"
    $env:PKG_CONFIG_PATH = "$${PKG_CONFIG_PATH:-}$$" + "$PATH_SEP" + "$child_parent"
}
"""
    return FunctionAndCall(text = text)

def cat(filepath):
    return "Get-Content -Path \"{}\"".format(filepath)

def cat_eof_start(filepath):
    return "@\""

def cat_eof_end(filepath):
    return "\"@ | Out-FIle -LiteralPath {}".format(filepath)

def redirect_out_err(from_process, to_file):
    return "& " + from_process + " 2>&1 | Out-File -LiteralPath " + to_file

def invoke(*args):
    return "& " + " ".join(args)

def assert_script_errors():
    return "Set-StrictMode -Version latest"

def cleanup_function(on_success, on_failure):
    text = """\
$ecode=$?
if ( $ecode -ne 0 ) {{
    {on_failure}
}}
""".format(
        on_failure = on_failure,
    )
    return FunctionAndCall(text = text, call = "trap { cleanup_function }")

def children_to_path(dir_):
    text = """\
if ( Test-Path -Path "{dir_}" -PathType Container ) {{
    $tools = Get-ChildItem -Path "$env:EXT_BUILD_DEPS/bin" -Depth 1 -Force -Filter "*.pc"
    if ($tools) {{
        ForEach-Object -InputObject $tools {{
            $should_add = (Test-Path -Path "$_" -PathType Container)
            $should_add = (((Get-Item "$_" -Force -ea SilentlyContinue).Attributes -band [IO.FileAttributes]::ReparsePoint ) -or $should_add)
            if ($should_add -eq $true) {{
                $env:PATH = "$env:PATH" + "$PATH_SEP" + "$tool"
            }}
        }}
    }}
}}
""".format(dir_ = dir_)
    return FunctionAndCall(text = text)

def define_absolute_paths(dir_, abs_path):
    return "##replace_in_files## {dir_} {REPLACE_VALUE} {abs_path}".format(
        dir_ = dir_,
        REPLACE_VALUE = "$env:EXT_BUILD_DEPS",
        abs_path = abs_path,
    )

def replace_absolute_paths(dir_, abs_path):
    return "##replace_in_files## {dir_} {abs_path} {REPLACE_VALUE}".format(
        dir_ = dir_,
        REPLACE_VALUE = "$env:EXT_BUILD_DEPS",
        abs_path = abs_path,
    )
