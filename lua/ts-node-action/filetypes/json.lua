local padding = {
  [","] = "%s ",
  [":"] = "%s ",
}

local toggle_multiline = require("ts-node-action.actions.toggle_multiline")(padding)

return {
  ["object"] = toggle_multiline,
  ["array"]  = toggle_multiline,
}
