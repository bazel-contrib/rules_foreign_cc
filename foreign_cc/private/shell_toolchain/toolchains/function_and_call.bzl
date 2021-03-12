# buildifier: disable=module-docstring
# buildifier: disable=name-conventions
FunctionAndCall = provider(
    doc = "Wrapper to pass function definition and (if custom) function call",
    fields = {
        "call": "How to call defined function, if different from <function-name> <arg1> ...<argn>",
        "text": "Function body, without wrapping function <name>() {} fragment.",
    },
)
