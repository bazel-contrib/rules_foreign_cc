###How to add a shell toolchain implementation for a custom platform:
(to modify the fragments of generated shell script)

- define your own shell toolchain file(s) by copying @rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains/impl:linux_commands.bzl,
and modifying the methods.
- create a mapping: a list of ToolchainMapping with the mappings between created file(s) and execution or/and target platform constraints.
- in the BUILD file of some package, call "register_mappings" macro from "@rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:defs.bzl", passing the mappings and toolchain_type_ = "@rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:shell_commands"
- in the WORKSPACE file of your main repository, when you initialize rules_foreign_cc, pass the mappings and the package, in which BUILD file you called "register_mappings" macro

Please look how it is done in this example.