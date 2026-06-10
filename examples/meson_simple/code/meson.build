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
  # On non-Windows, install the shared object to lib/. On Windows, omit the
  # install_dir override so meson uses its platform defaults: the DLL goes to
  # bin/ and the import library to lib/, matching rules_foreign_cc's out_dll_dir
  # (bin) / out_lib_dir (lib) defaults.
  shared_kwargs = {}
  if host_machine.system() != 'windows'
    shared_kwargs += {'install_dir': join_paths(get_option('prefix'), 'lib')}
  endif
  shared_library(
    'a_shared',
    'liba.cpp',
    # LIBA_SHARED_BUILD makes liba.h mark hello_liba as __declspec(dllexport)
    # on Windows so MSVC produces the a_shared.lib import library.
    cpp_args: cxx.get_supported_arguments() + ['-DLIBA_SHARED_BUILD'],
    link_args: get_option('shared_link_flags'),
    include_directories: include_directories('.'),
    install: true,
    kwargs: shared_kwargs,
  )
  if host_machine.system() == 'darwin'
    meson.add_install_script(
      'install_name_tool', '-id', '@rpath/liba_shared.dylib',
      get_option('prefix') / 'lib' / 'liba_shared.dylib',
    )
  endif
endif

install_headers('liba.h', subdir: 'include')
