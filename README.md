# ts-pack.nvim

A parser-only Treesitter manager for Neovim with a `vim.pack`-style lifecycle.

## Install

Add this plugin with your preferred Neovim package manager.

## Usage

```lua
require('ts-pack').setup()

require('ts-pack').add({
  {
    id = 'lua',
    src = 'https://github.com/tree-sitter-grammars/tree-sitter-lua',
    version = 'main',
  },
})
```
