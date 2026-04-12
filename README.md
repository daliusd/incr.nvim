# incr.nvim

⚠️⚠️⚠️NOTE⚠️⚠️⚠️: This plugin is not necessary anymore in nvim 0.12+. You can
get same behaviour using following keymap:

```lua
local keymap = vim.keymap.set
keymap('n', '<Tab>', ':normal van<cr>', opts)
keymap('v', '<Tab>', function()
  vim.api.nvim_feedkeys('an', 'v', false)
end)
keymap('n', '<S-Tab>', ':normal vin<cr>', opts)
keymap('v', '<S-Tab>', function()
  vim.api.nvim_feedkeys('in', 'v', false)
end)
```

This plugin uses nvim-treesitter to select nodes incrementally. You can start
selection in normal mode by clicking `tab` and then repeatedly clicking `tab`
select more scope. You can use `s-tab` to decrement selection.

## Installation

Using lazyvim.

```lua
  {
    'daliusd/incr.nvim',
    config = true,
  },
```

If you want to override default keys then use something like this:

```lua
  {
    'daliusd/incr.nvim',
    opts = {
        incr_key = '<tab>', -- increment selection key
        decr_key = '<s-tab>', -- decrement selection key
    },
  }
```

## History

nvim-treesitter main branch drop increment selection feature. From
https://github.com/nvim-treesitter/nvim-treesitter/issues/4767#issue-1698676665:

> incremental-selection mostly served as a proof-of-concept for
> non-highlighting uses of tree-sitter; if people are actively using it, they
> should consider moving it to a separate plugin (or seeing if textobjects
> don't serve this purposes even better); alternatively rewrite as simple node
> and scope textobjects;

This is basically gist of it. Initially I have tried to move this to my nvim
configuration as simple solution, but found out that simple solution was lacking
something as tree-sitter methods are not necessary doing what their
documentation says.

This does not match original nvim-treesitter incremental-selection feature - if
you are missing something feel free to create issue or even better PR.
