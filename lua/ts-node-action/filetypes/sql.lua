local actions = require("ts-node-action.actions")

local operators = {
    ["!="] = "=",
    ["="] = "!=",
    ["AND"] = "OR",
    ["OR"] = "AND",
    ["or"] = "and",
    ["and"] = "or",
    [">"] = "<",
    ["<"] = ">",
    [">="] = "<=",
    ["<="] = ">=",
    ["+"] = "-",
    ["-"] = "+",
    ["*"] = "/",
    ["/"] = "*",
}

local padding = {
    [","] = "%s ",
}

local uncollapsible = {
    ["term"] = true,
    ["column_definition"] = true,
}

return {
    ["keyword_true"]       = actions.toggle_boolean(),
    ["keyword_false"]      = actions.toggle_boolean(),
    ["binary_expression"]  = actions.toggle_operator(operators),
    ["keyword_and"]        = actions.toggle_operator(operators),
    ["keyword_or"]         = actions.toggle_operator(operators),
    ["select_expression"]  = actions.toggle_multiline(padding, uncollapsible),
    ["column_definitions"] = actions.toggle_multiline(padding, uncollapsible),
}
