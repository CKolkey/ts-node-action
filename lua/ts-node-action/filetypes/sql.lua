local helpers = require("ts-node-action.helpers")
local actions = require("ts-node-action.actions")

local padding = {
    [","] = "%s ",
}

local boolean_override = {
    ["true"] = "false",
    ["TRUE"] = "FALSE",
    ["false"] = "true",
    ["FALSE"] = "TRUE",
}

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
}

return {
    ["keyword_true"] = actions.toggle_boolean(boolean_override),
    ["keyword_false"] = actions.toggle_boolean(boolean_override),
    ["binary_expression"] = actions.toggle_operator(operators),
    ["keyword_and"] = actions.toggle_operator(operators),
    ["keyword_or"] = actions.toggle_operator(operators),
    ["select_expression"] = actions.toggle_multiline(padding, uncollapsible),
}
