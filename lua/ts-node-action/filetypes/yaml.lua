local actions = require("ts-node-action.actions")

return {
  ["boolean_scalar"] = actions.toggle_boolean(),
}
