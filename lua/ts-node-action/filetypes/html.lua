local actions = require("ts-node-action.actions")

return {
  ["attribute_value"] = actions.conceal_string()
}
