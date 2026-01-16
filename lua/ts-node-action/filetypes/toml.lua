local actions = require("ts-node-action.actions")

local padding = {
  [","] = "%s ",
}

return {
  ["array"] = actions.toggle_multiline(padding),
}
