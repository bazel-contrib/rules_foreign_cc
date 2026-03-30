project('meson_with_requirements')

# Mirror the Mesa usage pattern: resolve Python through Meson, then reuse that
# interpreter for child commands.
py = import('python').find_installation()
# Exercise Meson's supported module check path. This should only succeed when
# meson_with_requirements preserves pip-installed modules for child Python use.
py_with_mako = import('python').find_installation(modules : ['mako'])
expected_python_version = get_option('expected_python_version')

py_path = py.full_path().replace('\\', '/')

if not py_path.contains('.runfiles/')
  error('Expected Meson to use the Bazel toolchain Python from runfiles, but got "' + py.full_path() + '"')
endif

actual_python_version = run_command(
  py,
  '-c',
  'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")',
  check : true,
).stdout().strip()

if actual_python_version != expected_python_version
  error('Expected Python version "' + expected_python_version + '" but got "' + actual_python_version + '"')
endif

# Use Meson's own wrapper entrypoint for the "correct" runpython flow.
meson_prog = find_program('meson')

runpython_smoke = run_command(
  meson_prog,
  'runpython',
  files('render.py'),
  files('hello.txt.mako'),
  '-',
  expected_python_version,
  check : true,
)

# This target proves the runpython path can render a file with Mako.
runpython_target = custom_target(
  'hello_runpython',
  input : 'hello.txt.mako',
  output : 'hello_runpython.txt',
  command : [
    meson_prog,
    'runpython',
    files('render.py'),
    '@INPUT@',
    '@OUTPUT@',
    expected_python_version,
  ],
  build_by_default : true,
  install : true,
  install_dir : get_option('prefix'),
)

# This checks the Mesa-style path where Meson returns a Python interpreter and
# the project executes it directly.
prog_python_smoke = run_command(
  py,
  files('render.py'),
  files('hello.txt.mako'),
  '-',
  expected_python_version,
  check : true,
)

# This target proves the direct prog_python flow can also render with Mako.
prog_python_target = custom_target(
  'hello_prog_python',
  input : 'hello.txt.mako',
  output : 'hello_prog_python.txt',
  command : [
    py,
    files('render.py'),
    '@INPUT@',
    '@OUTPUT@',
    expected_python_version,
  ],
  build_by_default : true,
  install : true,
  install_dir : get_option('prefix'),
)
