local padding = {
  [","] = "%s ",
  ["{"] = "%s ",
  ["}"] = " %s",
  ["="] = " %s ",
  ["or"] = " %s ",
  ["and"] = " %s ",
  ["+"] = " %s ",
  ["-"] = " %s ",
  ["*"] = " %s ",
  ["/"] = " %s ",
}

local toggle_boolean   = require("ts-node-action.actions.toggle_boolean")
local toggle_multiline = require("ts-node-action.actions.toggle_multiline")(padding)

return {
  ["false"]             = toggle_boolean,
  ["true"]              = toggle_boolean,
  ["table_constructor"] = toggle_multiline,
  ["arguments"]         = toggle_multiline,
}
