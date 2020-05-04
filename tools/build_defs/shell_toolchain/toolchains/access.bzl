load("//tools/build_defs/shell_toolchain/toolchains:commands.bzl", "PLATFORM_COMMANDS")
load(":function_and_call.bzl", "FunctionAndCall")

_function_and_call_type = type(FunctionAndCall(text = ""))

def create_context(ctx):
    return struct(
        shell = ctx.toolchains["@rules_foreign_cc//tools/build_defs/shell_toolchain/toolchains:shell_commands"].data,
        prelude = {},
    )

def call_shell(shell_context, method_, *args):
    """ Calls the 'method_' shell command from the toolchain.
 Checks the number and types of passed arguments.
 If the command returns the resulting text wrapped into FunctionAndCall provider,
 puts the text of the function into the 'prelude' dictionary in the 'shell_context',
 and returns only the call of that function.
"""
    check_argument_types(method_, args)

    func_ = getattr(shell_context.shell, method_)
    result = func_(*args)

    if type(result) == _function_and_call_type:
        # If needed, add function definition to the prelude part of the script
        if not shell_context.prelude.get(method_):
            define_function = getattr(shell_context.shell, "define_function")
            shell_context.prelude[method_] = define_function(method_, result.text)

        # use provided method of calling a defined function or use default
        if hasattr(result, "call"):
            return result.call
        return " ".join([method_] + [_wrap_if_needed(str(arg)) for arg in args])

    return result

def _wrap_if_needed(arg):
    return "\"" + arg + "\"" if arg.find(" ") >= 0 else arg

def check_argument_types(method_, args_list):
    descriptor = PLATFORM_COMMANDS[method_]
    args_info = descriptor.arguments

    if len(args_list) != len(args_info):
        fail("Wrong number ({}) of arguments ({}) in a call to '{}'".format(
            len(args_list),
            str(args_list),
            method_,
        ))

    for idx in range(0, len(args_list)):
        if type(args_list[idx]) != args_info[idx].type_:
            fail("Wrong argument '{}' type: '{}'".format(args_info[idx].name, type(args_list[idx])))
