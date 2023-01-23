local helpers = require("ts-node-action.helpers")

local boolean_pair_default = {
  ["true"]  = "false",
  ["false"] = "true",
}

return function(boolean_pair_override)
  local boolean_pair = vim.tbl_deep_extend("force",
    boolean_pair_default, boolean_pair_override or {})

  local function action(node)
    return boolean_pair[helpers.node_text(node)] or helpers.node_text(node)
  end

  return { { action, name = "Toggle Boolean" } }
end
