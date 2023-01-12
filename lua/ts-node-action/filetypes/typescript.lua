local padding = {
  [","] = "%s ",
  [":"] = "%s ",
  ["{"] = "%s ",
  ["}"] = " %s",
}

local toggle_multiline = require("ts-node-action.actions.toggle_multiline")(padding)
local cycle_case       = require("ts-node-action.actions.cycle_case")

return {
  ["object"]              = toggle_multiline,
  ["array"]               = toggle_multiline,
  ["statement_block"]     = toggle_multiline,
  ["property_identifier"] = cycle_case,
}
