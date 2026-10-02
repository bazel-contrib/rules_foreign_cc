project('hello')

# Resolve Python the way real projects do. rules_foreign_cc hands meson the
# exec-configuration interpreter ($PYTHON3), so this is hermetic.
py = import('python').find_installation()

# No quotes inside the one-liner: it is quoted once more by ninja on Windows.
custom_target(
  'hello',
  output : 'hello.txt',
  command : [py, '-c', 'import pathlib, sys; pathlib.Path(sys.argv[1]).write_text(sys.version)', '@OUTPUT@'],
  build_by_default : true,
  install : true,
  install_dir : get_option('prefix'),
)
