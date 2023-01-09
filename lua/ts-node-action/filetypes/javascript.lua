local actions = require("ts-node-action.actions")

local padding = {
  [","] = "%s ",
  [":"] = "%s ",
  ["{"] = "%s ",
  ["}"] = " %s",
}

return {
  ["object"]              = actions.toggle_multiline(padding),
  ["array"]               = actions.toggle_multiline(padding),
  ["statement_block"]     = actions.toggle_multiline(padding),
  ["property_identifier"] = actions.cycle_case(),
}
