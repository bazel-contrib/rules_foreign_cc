project('liba', 'cpp')

builddir = 'rules_foreign_cc_build'

cxx = meson.get_compiler('cpp')

liba = static_library(
  'a',
  'liba.cpp',
  cpp_args: cxx.get_supported_arguments(),
  include_directories: include_directories('.'),
  install: true,
  install_dir: join_paths(get_option('prefix'), 'lib'),
)

if get_option('build_shared')
  shared_library(
    'a_shared',
    'liba.cpp',
    cpp_args: cxx.get_supported_arguments(),
    link_args: get_option('shared_link_flags'),
    include_directories: include_directories('.'),
    install: true,
    install_dir: join_paths(get_option('prefix'), 'lib'),
  )
  if host_machine.system() == 'darwin'
    meson.add_install_script(
      'install_name_tool', '-id', '@rpath/liba_shared.dylib',
      get_option('prefix') / 'lib' / 'liba_shared.dylib',
    )
  endif
endif

install_headers('liba.h', subdir: 'include')
