local toggle_boolean = require("ts-node-action.actions.toggle_boolean")
local cycle_case     = require("ts-node-action.actions.cycle_case")

return {
  ["true"]          = toggle_boolean,
  ["false"]         = toggle_boolean,
  ["identifier"]    = cycle_case,
  ["variable_name"] = cycle_case,
}
