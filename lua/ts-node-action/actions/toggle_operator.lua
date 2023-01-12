local helpers = require("ts-node-action.helpers")

local default_operators = {
  ["!="] = "==",
  ["=="] = "!=",
  [">"]  = "<",
  ["<"]  = ">",
  [">="] = "<=",
  ["<="] = ">=",
}

return function(operator_override)
  local operators = vim.tbl_extend("force",
    default_operators, operator_override or {})

  return function(node)
    local replacement = {}
    for child, _ in node:iter_children() do
      local text = helpers.node_text(child)
      if operators[text] then
        table.insert(replacement, operators[text])
      else
        table.insert(replacement, text)
      end
    end
    return table.concat(replacement, " ")
  end
end
