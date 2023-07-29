local actions = require("ts-node-action.actions")

local padding = {
  [","] = "%s ",
  [":"] = "%s ",
}

return {
  ["object"] = actions.toggle_multiline(padding),
  ["array"] = actions.toggle_multiline(padding),
}
