local actions = require("ts-node-action.actions")
local helpers = require("ts-node-action.helpers")

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

local padding = {
	[","] = "%s ",
	["="] = " %s ",
}

--- @param node TSNode
local function toggle_multiline_args(node)
	local structure = helpers.destructure_node(node)
	if (type(structure["arguments"]) == "table") or (type(structure["arguments"]) == "string") then
	else
		vim.print("No arguments")
		return
	end

	local range_end = {}
	range_end = { node:named_child(0):range() }
	local replacement

	if helpers.node_is_multiline(node) then
		local tbl = actions.toggle_multiline(padding)
		replacement = tbl[1][1](node)
	else
		replacement = { structure["function"] .. "(" }
		for k in string.gmatch(structure.arguments, "([^,]+)") do
			table.insert(replacement, k .. ",")
		end
		replacement[#replacement] = string.gsub(replacement[#replacement], "(.*)%,$", "%1")
		table.insert(replacement, ")")
	end

	return replacement, { cursor = { col = range_end[4] - range_end[2] }, format = true }
end
return {
	["true"] = actions.toggle_boolean(boolean_override),
	["false"] = actions.toggle_boolean(boolean_override),
	["binary"] = actions.toggle_operator(operators),
	["call"] = { { toggle_multiline_args, name = "Toggle Multiline Arguments" } },
	["formal_parameters"] = actions.toggle_multiline(padding),
}
