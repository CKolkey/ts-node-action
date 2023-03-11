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

  local function action(node)
    if node:child_count() == 0 then
      local text = helpers.node_text(node)
      if operators[text] then
        return operators[text]
      end
    else
      for child, _ in node:iter_children() do
        if child:named() == false then
          local text = helpers.node_text(child)
          if operators[text] then
            return operators[text], { target = child }
          end
        end
      end
    end
  end

  return { { action, name = "Toggle Operator" } }
end
