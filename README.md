# TS Node Action

A framework for running functions on Tree-sitter nodes, and updating the buffer with the result.

![cycle case](https://user-images.githubusercontent.com/7228095/210154055-8851210e-e8e1-4ba3-a474-0be373df8d1b.gif)

![multiline](https://user-images.githubusercontent.com/7228095/210153839-5009dbed-db7a-4b1c-b5c9-879b90f32a64.gif)

![condition formatting](https://user-images.githubusercontent.com/7228095/210153712-8be29018-00a3-427f-8a59-959e705e12c6.gif)

![ternerizing](https://user-images.githubusercontent.com/7228095/210153716-2fde6101-352b-4ef9-ba00-0842e6749201.gif)

![operator flipflop](https://user-images.githubusercontent.com/7228095/210153726-3f5da644-ae1f-4288-b52b-e12a9c757293.gif)

![split join blocks](https://user-images.githubusercontent.com/7228095/210153731-a2c2a717-e7ae-4330-9664-11ba4ed3c005.gif)

## Installation

`Lazy.nvim`:
```lua
{
    'ckolkey/ts-node-action',
     dependencies = { 'nvim-treesitter' },
     config = function() -- Optional
         require("ts-node-action").setup({})
     end
},
```

`packer`:
```lua
use({
    'ckolkey/ts-node-action',
     requires = { 'nvim-treesitter' },
     config = function() -- Optional
         require("ts-node-action").setup({})
     end
})
```

**Note**: It's not required to call `require("ts-node-action").setup()` to initialize the plugin, but a table can be
passed into the setup function to specify new actions for nodes or additional filetypes.

## Usage

Bind `require("ts-node-action").node_action` to something. This is left up to the user.

For example, this would bind the function to `K`:
```lua
vim.keymap.set({ "n" }, "K", require("ts-node-action").node_action, { desc = "Trigger Node Action" })
```

## Configuration

The `setup()` function accepts a table that conforms to the following schema:

```lua
{
    ['*'] = { -- Global table is checked for all filetypes
        ["node_type"] = fn,
        ...
    },
    filetype = {
        ["node_type"] = fn,
        ...
    },
    ...
}
```

- `filetype` should be the value of `vim.o.filetype`, or `'*'` for the global table
- `node_type` should be the value of `vim.treesitter.get_node_at_cursor()`

A definition on the `filetype` table will take precedence over the `*` (global) table.

### Multiple Actions for a Node Type

To define multiple actions for a node type, structure your `node_type` value as a table of tables, like so:

```lua
["node_type"] = {
  { function_one, name = "Action One" },
  { function_two, name = "Action Two" },
}
```

`vim.ui.select` will use the value of `name` to when prompting you on which action to perform.

## Writing your own Node Actions

All node actions should be a function that takes one argument: the tree-sitter node under the cursor.

You can read more about their API via `:help tsnode`

This function can return one or two values:

- The first being the text to replace the node with. The replacement text can be either a `"string"` or
`{ "table", "of", "strings" }`. With a table of strings, each string will be on it's own line.

- The second (optional) returned value is a table of options. Supported keys are:
-- `cursor`
-- `callback`
-- `format`

Here's how that can look.

```lua
{ cursor = { row = 0, col = 0 }, callback = function() ... end , format = true }
```

#### `cursor`
If the `cursor` key is present with an empty table value, the cursor will be moved to the start of the line where the
current node is (`row = 0` `col = 0` relative to node `start_row` and `start_col`).

#### `callback`
If `callback` is present, it will simply get called without arguments after the buffer has been updated, and after the
cursor has been positioned.

#### `format`
Boolean value. If `true`, will run `==` operator on new buffer text.

Here's a simplified example of how a node-action function gets called:
```lua
local action = node_actions[vim.o.filetype][node:type()]
local replacement, opts = action(node)
replace_node(node, replacement, opts or {})
```

## API

`require("ts-node-action").node_action()`
Main function for plugin. Should be assigned by user, and when called will attempt to run the assigned function for the
node your cursor is currently on.
<hr>

`require("ts-node-action").debug()`
Prints some helpful information about the current node, as well as the loaded node actions for all filetypes

## Helpers

`require("ts-node-action.helpers").node_text(node)`
```
@node: tsnode
@return: string
```
Returns the text of the specified node.
<hr>

`require("ts-node-action.helpers").multiline_node(node)`
```
@node: tsnode
@return: boolean
```
Returns true if node spans multiple lines, and false if it's a single line.
<hr>

`require("ts-node-action.helpers").padded_node_text(node, padding)`
```
@node: tsnode
@padding: table
@return: string
```
For formatting unnamed tsnodes. For example, if you pass in an unnamed node representing the text `,`, you could pass in
a `padding` table (below) to add a trailing whitespace to `,` nodes.
```lua
{ [","] = "%s " }
```

Nodes not specified in table are returned unchanged.

## Builtin Actions

**Global** _(Applies to all filetypes)_
```lua
{
  ["true"]       = toggle_boolean,
  ["false"]      = toggle_boolean,
  ["identifier"] = cycle_case,
}
```

**Ruby**
```lua
{
  ["true"]              = toggle_boolean,
  ["false"]             = toggle_boolean,
  ["array"]             = toggle_multiline,
  ["hash"]              = toggle_multiline,
  ["argument_list"]     = toggle_multiline,
  ["method_parameters"] = toggle_multiline,
  ["identifier"]        = cycle_case,
  ["constant"]          = cycle_case,
  ["block"]             = toggle_block,
  ["do_block"]          = toggle_block,
  ["binary"]            = toggle_operator,
  ["if"]                = handle_conditional,
  ["unless"]            = handle_conditional,
  ["if_modifier"]       = multiline_conditional,
  ["unless_modifier"]   = multiline_conditional,
  ["conditional"]       = expand_ternary,
  ["pair"]              = toggle_hash_style,
}
```

**JSON**
```lua
{
  ["object"] = toggle_multiline,
  ["array"]  = toggle_multiline,
}
```

**Lua**
```lua
{
  ["table_constructor"] = toggle_multiline,
  ["arguments"]         = toggle_multiline,
  ["true"]              = toggle_boolean,
  ["false"]             = toggle_boolean,
  ["identifier"]        = cycle_case,
}
```

**Javascript**
```lua
{
  ["object"]              = toggle_multiline,
  ["array"]               = toggle_multiline,
  ["statement_block"]     = toggle_multiline,
  ["identifier"]          = cycle_case,
  ["property_identifier"] = cycle_case,
  ["true"]                = toggle_boolean,
  ["false"]               = toggle_boolean,
}
```

**Python**
```lua
{
  ["dictionary"] = toggle_multiline,
  ["list"]       = toggle_multiline,
  ["true"]       = toggle_boolean,
  ["false"]      = toggle_boolean,
  ["identifier"] = cycle_case,
}
```

## Contributing

If you come up with something that would be a good fit, pull requests for node actions are welcome!

Visit: https://www.github.com/ckolkey/ts-node-action
