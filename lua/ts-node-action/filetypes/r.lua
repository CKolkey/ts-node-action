local actions = require("ts-node-action.actions")

local boolean_override = {
	["TRUE"] = "FALSE",
	["FALSE"] = "TRUE",
}

local operators = {
	["!="] = "==",
	["=="] = "!=",
	[">"] = "<",
	["<"] = ">",
	[">="] = "<=",
	["<="] = ">=",
	["+"] = "-",
	["-"] = "+",
	["*"] = "/",
	["/"] = "*",
	["|"] = "&",
	["&"] = "|",
	["||"] = "&&",
	["&&"] = "||",
}

return {
	["true"] = actions.toggle_boolean(boolean_override),
	["false"] = actions.toggle_boolean(boolean_override),
	["binary"] = actions.toggle_operator(operators),
}
