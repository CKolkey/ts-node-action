# TS Node Action

A framework for running functions on Tree-sitter nodes, and updating the buffer
with the result.

<!-- mdformat-toc start --slug=github --no-anchors --maxlevel=3 --minlevel=2 -->

- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
  - [Multiple Actions for a Node Type](#multiple-actions-for-a-node-type)
- [Writing your own Node Actions](#writing-your-own-node-actions)
  - [Options](#options)
- [API](#api)
- [null-ls Integration](#null-ls-integration)
- [Helpers](#helpers)
- [Builtin Actions](#builtin-actions)
- [Testing](#testing)
- [Contributing](#contributing)

<!-- mdformat-toc end -->

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
     opts = {},
},
```

`packer`:

```lua
use({
    'ckolkey/ts-node-action',
     requires = { 'nvim-treesitter' },
     config = function()
         require("ts-node-action").setup({})
     end
})
```

> \[!NOTE\]
> It's not required to call `require("ts-node-action").setup()` to
> initialize the plugin, but a table can be passed into the setup function to
> specify new actions for nodes or additional langs.

## Usage

Bind `require("ts-node-action").node_action` to something. This is left up to
the user.

For example, this would bind the function to `K`:

```lua
vim.keymap.set(
    { "n" },
    "K",
    require("ts-node-action").node_action,
    { desc = "Trigger Node Action" },
)
```

If `tpope/vim-repeat` is installed, calling `node_action()` is dot-repeatable.

If `setup()` is called, user commands `:NodeAction` and `:NodeActionDebug` are
defined.

See `available_actions()` below for how to set this up with LSP Code Actions.

## Configuration

The `setup()` function accepts a table that conforms to the following schema:

```lua
{
    ['*'] = { -- Global table is checked for all langs
        ["node_type"] = fn,
        ...
    },
    lang = {
        ["node_type"] = fn,
        ...
    },
    ...
}
```

- `lang` should be the treesitter parser lang, or `'*'` for the global table
- `node_type` should be the value of `vim.treesitter.get_node_at_cursor()`

A definition on the `lang` table will take precedence over the `*` (global)
table.

### Multiple Actions for a Node Type

To define multiple actions for a node type, structure your `node_type` value as
a table of tables, like so:

```lua
["node_type"] = {
  { function_one, name = "Action One" },
  { function_two, name = "Action Two" },
}
```

`vim.ui.select` will use the value of `name` to when prompting you on which
action to perform.

If you want to bypass `vim.ui.select` and instead just want all actions to be
applied without prompting, you can pass `ask = false` as an argument in the
`node_type` value. Using the same example as above, it would look like this:

```lua
["node_type"] = {
  { function_one, name = "Action One" },
  { function_two, name = "Action Two" },
  ask = false,
}
```

## Writing your own Node Actions

All node actions should be a function that takes one argument: the tree-sitter
node under the cursor.

You can read more about their API via `:help tsnode`

This function can return one or two values:

- The first being the text to replace the node with. The replacement text can be
  either a `"string"` or `{ "table", "of", "strings" }`. With a table of
  strings, each string will be on it's own line.

- The second (optional) returned value is a table of options. Supported keys
  are: `cursor`, `callback`, `format`, and `target`.

Here's how that can look.

```lua
{
  cursor   = { row = 0, col = 0 },
  callback = function() ... end,
  format   = true,
  target   = <tsnode>
}
```

### Options

#### `cursor`

If the `cursor` key is present with an empty table value, the cursor will be
moved to the start of the line where the current node is (`row = 0` `col = 0`
relative to node `start_row` and `start_col`).

#### `callback`

If `callback` is present, it will simply get called without arguments after the
buffer has been updated, and after the cursor has been positioned.

#### `format`

Boolean value. If `true`, will run `=` operator on new buffer text. Requires
`indentexpr` to be set.

#### `target`

TSNode. If present, this node will be used as the target for replacement instead
of the node under your cursor.

Here's a simplified example of how a node-action function gets called:

```lua
local action = node_actions[lang][node:type()]
local replacement, opts = action(node)
replace_node(node, replacement, opts or {})
```

## API

`require("ts-node-action").node_action()` Main function for plugin. Should be
assigned by user, and when called will attempt to run the assigned function for
the node your cursor is currently on.

______________________________________________________________________

`require("ts-node-action").debug()` Prints some helpful information about the
current node, as well as the loaded node actions for all langs

______________________________________________________________________

`require("ts-node-action").available_actions()` Exposes the function assigned to
the node your cursor is currently on, as well as its name

______________________________________________________________________

## null-ls Integration

Users can set up integration with
[null-ls](https://github.com/jose-elias-alvarez/null-ls.nvim) and use it to
display available node actions by registering the builtin `ts_node_action` code
action source

```lua
local null_ls = require("null-ls")
null_ls.setup({
  sources = {
    null_ls.builtins.code_actions.ts_node_action,
    ...
  }
})
```

This will present the available node action(s) for the node under your cursor
alongside your `lsp`/`null-ls` code actions.

______________________________________________________________________

## Helpers

```lua
require("ts-node-action.helpers").node_text(node)
```

```lua
@node: tsnode
@return: string
```

Returns the text of the specified node.

______________________________________________________________________

```lua
require("ts-node-action.helpers").node_is_multiline(node)
```

```lua
@node: tsnode
@return: boolean
```

Returns true if node spans multiple lines, and false if it's a single line.

______________________________________________________________________

```lua
require("ts-node-action.helpers").padded_node_text(node, padding)
```

```lua
@node: tsnode
@padding: table
@return: string
```

For formatting unnamed tsnodes. For example, if you pass in an unnamed node
representing the text `,`, you could pass in a `padding` table (below) to add a
trailing whitespace to `,` nodes.

```lua
{ [","] = "%s " }
```

Nodes not specified in table are returned unchanged.

## Builtin Actions

<details>
<!-- markdownlint-disable-next-line no-inline-html -->
<summary><h3>Cycle Case</h3></summary>

```lua
require("ts-node-action.actions").cycle_case(formats)
```

```lua
@param formats table|nil
```

`formats` param can be a table of strings specifying the different formats to
cycle through. By default it's

```lua
{ "snake_case", "pascal_case", "screaming_snake_case", "camel_case" }
```

A table can also be used in place of a string to implement a custom formatter.
Every format is a table that implements the following interface:

- pattern (string)
- apply (function)
- standardize (function)

#### `pattern` <!-- markdownlint-disable-line header-increment -->

A Lua pattern (string) that matches the format

#### `apply`

A function that takes a _table_ of standardized strings as it's argument, and
returns a _string_ in the format

#### `standardize`

A function that takes a _string_ in this format, and returns a table of strings,
all lower case, no special chars. ie:

```lua
    standardize("ts_node_action") -> { "ts", "node", "action" }
    standardize("tsNodeAction")   -> { "ts", "node", "action" }
    standardize("TsNodeAction")   -> { "ts", "node", "action" }
    standardize("TS_NODE_ACTION") -> { "ts", "node", "action" }
```

> \[!NOTE\]
> The order of formats can be important, as some identifiers are the same
> for multiple formats. Take the string 'action' for example. This is a match for
> both snake*case \_and* camel_case. It's therefore important to place a format
> between those two so we can correcly change the string.

______________________________________________________________________

</details>

Builtin actions are all higher-order functions so they can easily have options
overridden on a per-lang basis. Check out the implementations under
`lua/filetypes/` to see how!

<!-- markdownlint-disable line-length -->

|                            | (\*) | Ruby | js/ts/tsx/jsx | Lua | Python | PHP | Rust | C#  | JSON | HTML | YAML | R   |
| -------------------------- | ---- | ---- | ------------- | --- | ------ | --- | ---- | --- | ---- | ---- | ---- | --- |
| `toggle_boolean()`         | ✅    | ✅    | ✅             | ✅   | ✅      | ✅   | ✅    | ✅    |      |      | ✅    | ✅   |
| `cycle_case()`             | ✅    | ✅    | ✅             | ✅   | ✅      | ✅   | ✅    | ✅    |      |      |      | ✅   |
| `cycle_quotes()`           | ✅    | ✅    | ✅             | ✅   | ✅      | ✅   |      |      |      |      |      | ✅   |
| `toggle_multiline()`       |      | ✅    | ✅             | ✅   | ✅      | ✅   |  ✅   |      | ✅    |      |      | ✅   |
| `toggle_operator()`        |      | ✅    | ✅             | ✅   | ✅      | ✅   |       |   ✅  |      |      |      | ✅   |
| `toggle_int_readability()` |      | ✅    | ✅             |     | ✅      | ✅   | ✅     | ✅    | ✅    |      |      |     |
| `toggle_block()`           |      | ✅    |               |     |        |     |       |      |      |      |      |     |
| if/else \<-> ternery       |      | ✅    |               |     | ✅      |     |      |      |      |      |      |     |
| if block/postfix           |      | ✅    |               |     |        |     |      |      |      |      |      |     |
| `toggle_hash_style()`      |      | ✅    |               |     |        |     |      |      |      |      |      |     |
| `conceal_string()`         |      |      | ✅             |     |        |     |      |      |      | ✅    |      |     |

<!-- markdownlint-enable line-length -->

## Testing

To run the test suite, clone the repo and run `./run_spec`. It should pull all
dependencies into `spec/support/` on first run, then execute the tests.

This is still a little WIP.

## Contributing

If you come up with something that would be a good fit, pull requests for node
actions are welcome!

Visit: <https://www.github.com/ckolkey/ts-node-action>
