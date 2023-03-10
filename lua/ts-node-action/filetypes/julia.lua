local actions = require("ts-node-action.actions")

return {
	["operator"] = actions.toggle_operator(),
}
