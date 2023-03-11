local operators = {
    [">"] = "<",
    ["<"] = ">",
    [">="] = "<=",
    ["<="] = ">=",
    ["+"] = "-",
    ["-"] = "+",
    ["*"] = "/",
    ["/"] = "*",
    ["!="] = "==",
    ["=="] = "!=",
    ["∉"] = "∈",
    ["∈"] = "∉",
}

local boolean = {
    ["true"] = "false",
    ["false"] = "true",
}

local padding = {
    [","] = "%s ",
    [";"] = "%s ",
}

local actions = require "ts-node-action.actions"
return {
    ["identifier"] = actions.cycle_case(),
    ["boolean_literal"] = actions.toggle_boolean(boolean),
    ["integer_literal"] = actions.toggle_int_readability(),
    ["dictionary"] = actions.toggle_multiline(padding, {}),
    ["set"] = actions.toggle_multiline(padding, {}),
    ["list"] = actions.toggle_multiline(padding, {}),
    ["tuple"] = actions.toggle_multiline(padding, {}),
    ["argument_list"] = actions.toggle_multiline(padding, {}),
    ["parameters"] = actions.toggle_multiline(padding, {}),
    ["list_comprehension"] = actions.toggle_multiline(padding, {}),
    ["vector_expression"] = actions.toggle_multiline(padding, {}),
    ["set_comprehension"] = actions.toggle_multiline(padding, {}),
    ["dictionary_comprehension"] = actions.toggle_multiline(padding, {}),
    ["generator_expression"] = actions.toggle_multiline(padding, {}),
    ["operator"] = actions.toggle_operator(operators),
}
