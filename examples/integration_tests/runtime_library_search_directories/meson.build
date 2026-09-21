project('runtime_search', 'c')

runtime_chain_component = get_option('runtime_chain_component')
runtime_test_family = get_option('runtime_test_family')
shared_ldflags = get_option('shared_ldflags')
c = meson.get_compiler('c')

dep_lib_dirs = run_command(
  'sh',
  '-c',
  'if [ -d "$EXT_BUILD_DEPS" ]; then find "$EXT_BUILD_DEPS" -type d -name lib -print | paste -sd: -; fi',
  check: true,
).stdout().strip()
dep_lib_dirs = dep_lib_dirs == '' ? [] : dep_lib_dirs.split(':')

compile_args = [
  '-DRUNTIME_TEST_FAMILY="@0@"'.format(runtime_test_family),
]
include_dirs = include_directories('src')
install_lib_dir = join_paths(get_option('prefix'), 'lib')
install_bin_dir = join_paths(get_option('prefix'), 'bin')

# Meson rewrites Darwin install names to install paths during install. This
# fixture repairs them so the test remains focused on runtime search paths.
if host_machine.system() == 'darwin'
  meson.add_install_script('fix_darwin_install_names.sh')
endif

if runtime_chain_component == 'leaf'
  shared_library(
    'leaf',
    'src/leaf.c',
    c_args: compile_args,
    include_directories: include_dirs,
    install: true,
    install_dir: install_lib_dir,
    link_args: shared_ldflags,
  )
elif runtime_chain_component == 'middle'
  leaf_dep = c.find_library('leaf', dirs: dep_lib_dirs, required: true)
  shared_library(
    'middle',
    'src/middle.c',
    c_args: compile_args,
    dependencies: leaf_dep,
    include_directories: include_dirs,
    install: true,
    install_dir: install_lib_dir,
    link_args: shared_ldflags,
  )
elif runtime_chain_component == 'app'
  middle_dep = c.find_library('middle', dirs: dep_lib_dirs, required: true)
  executable(
    'runtime_app',
    'src/app.c',
    c_args: compile_args,
    dependencies: middle_dep,
    include_directories: include_dirs,
    install: true,
    install_dir: install_bin_dir,
  )
elif runtime_chain_component == 'bundle'
  leaf_lib = shared_library(
    'leaf',
    'src/leaf.c',
    c_args: compile_args,
    include_directories: include_dirs,
    install: true,
    install_dir: install_lib_dir,
    link_args: shared_ldflags,
  )
  middle_lib = shared_library(
    'middle',
    'src/middle.c',
    c_args: compile_args,
    include_directories: include_dirs,
    install: true,
    install_dir: install_lib_dir,
    link_args: shared_ldflags,
    link_with: leaf_lib,
  )
  executable(
    'runtime_app',
    'src/app.c',
    c_args: compile_args,
    include_directories: include_dirs,
    install: true,
    install_dir: install_bin_dir,
    link_with: middle_lib,
  )
else
  error('runtime_chain_component must be one of: leaf, middle, app, bundle')
endif
