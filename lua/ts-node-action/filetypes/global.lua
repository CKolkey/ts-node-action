local actions = require("ts-node-action.actions")

return {
  ["true"]          = actions.toggle_boolean(),
  ["false"]         = actions.toggle_boolean(),
  ["boolean"]       = actions.toggle_boolean(),
  ["identifier"]    = actions.cycle_case(),
  ["variable_name"] = actions.cycle_case(),
  ["string"]        = actions.cycle_quotes(),
}
