# ts-pack.nvim

Lua-only Tree-sitter parser management for Neovim, shaped after `vim.pack`.

`ts-pack.nvim` does not install parser binaries automatically and does not ship
user commands or `plugin/` startup files. Call the Lua API with complete parser
specs:

```lua
local ts_pack = require('ts-pack')

ts_pack.add({
  {
    src = 'https://github.com/tree-sitter/tree-sitter-lua',
    name = 'lua',
    version = 'main',
    branch = nil,
    data = {
      -- Optional parser metadata.
      filetype = nil,
    },

    -- Optional parser build fields.
    location = nil,
    path = nil,
    queries = nil,
    generate = nil,
    generate_from_json = nil,
  },
})
```

Keep the same `add()` call in your config. It registers the parser specs for
the current session, applies parser metadata such as filetype associations, and
installs missing parser artifacts.

If you do not want to write every parser spec by hand, use the optional parser
library:

```lua
local ts_pack = require('ts-pack')
local library = require('ts-pack.library')

ts_pack.add(library.select({
  'lua',
  'bash',
  'tsx',
}))
```

## API

```lua
require('ts-pack').add(specs, opts)
require('ts-pack').update(names, opts)
require('ts-pack').del(names, opts)
require('ts-pack').get(names, opts)
```

`specs` is always a list. `name` defaults to the repository basename with a
leading `tree-sitter-` stripped. `branch` limits clone/fetch to a specific
remote branch and is used as `origin/<branch>` when `version` is unset. Duplicate
specs for the same parser name must agree on `src`, `version`, and `branch`.
`names` is an optional list of parser names; if omitted, the active parsers from
the current session are used.

Set `data.filetype` when a parser should be used for filetypes that do not match
the parser name. The value may be a string or a list of strings and is registered
with `vim.treesitter.language.register()` during `add()`:

```lua
ts_pack.add({
  {
    src = 'https://github.com/tree-sitter/tree-sitter-typescript',
    name = 'tsx',
    data = {
      filetype = { 'typescriptreact', 'typescript.tsx' },
    },
  },
})
```

## Parser library

`require('ts-pack.library')` exposes a bundled registry of upstream parser specs:

```lua
local library = require('ts-pack.library')

library.registry.lua
-- {
--   src = 'https://github.com/tree-sitter/tree-sitter-lua',
--   version = '...',
--   data = { filetype = ... },
-- }
```

Use `library.select(names)` to turn parser names into specs accepted by
`ts_pack.add()`. The returned specs are deep copies and include each parser
`name`. Parser dependencies from `requires` are expanded before the parser that
needs them, duplicates are removed, and unknown parser names raise an error.

```lua
local ts_pack = require('ts-pack')
local library = require('ts-pack.library')

-- Adds `typescript` before `tsx`, because `tsx` requires it.
ts_pack.add(library.select({ 'tsx' }), { async = true })
```

## Updating parsers

Call `add()` with the complete specs first, then call `update()`.

```lua
local ts_pack = require('ts-pack')

ts_pack.add({
  {
    src = 'https://github.com/tree-sitter/tree-sitter-lua',
    name = 'lua',
    version = 'main',
  },
})

-- Update one parser.
ts_pack.update({ 'lua' })

-- Update every parser registered by add() in this session.
ts_pack.update()

-- Start an update in the background.
ts_pack.update({ 'lua' }, { async = true })
```

By default, `update()` reuses the lockfile revision when one exists. To update
to the spec `version`, pass `target = 'version'`:

```lua
ts_pack.update({ 'lua' }, { target = 'version' })
```

To restore the lockfile revision explicitly:

```lua
ts_pack.update({ 'lua' }, { target = 'lockfile' })
```

## Deleting parsers

Call `del()` with parser names to remove installed artifacts and the lockfile
entry:

```lua
local ts_pack = require('ts-pack')

ts_pack.add({
  {
    src = 'https://github.com/tree-sitter/tree-sitter-lua',
    name = 'lua',
    version = 'main',
  },
})

-- Delete one parser.
ts_pack.del({ 'lua' })

-- Delete every parser registered by add() in this session.
ts_pack.del()
```

Deleting a parser removes:

- `parser/<name>.so`
- `parser-info/<name>.revision`
- `queries/<name>/`
- the parser entry from `ts-pack-lock.json`

Supported options follow `vim.pack` naming where they apply:

- `offline = true` prevents git clone/fetch.
- `target = 'version'` installs the spec `version`.
  When `version` is unset and `branch` is set, it installs `origin/<branch>`.
- `target = 'lockfile'` restores the lockfile revision.
- `info = false` keeps `get()` from reading extra lockfile/install metadata.
- `async = true` registers the specs immediately and installs missing parsers in
  a coroutine when passed to `add()`. It updates active parsers in a coroutine
  when passed to `update()`. Both paths yield around clone/fetch/build
  subprocesses so startup does not wait for parser installation.

Parser artifacts are installed under `stdpath('data')/site`:

- `parser/<name>.so`
- `parser-info/<name>.revision`
- `queries/<name>/` when `spec.queries` is provided

The lockfile is written to:

```lua
vim.fs.joinpath(vim.fn.stdpath('config'), 'ts-pack-lock.json')
```

Its shape is:

```json
{
  "parsers": {
    "lua": {
      "src": "https://github.com/tree-sitter/tree-sitter-lua",
      "rev": "git-commit",
      "version": "main",
      "data": null
    }
  }
}
```

## Acknowledgements

`ts-pack.nvim` is built on ideas and implementation patterns from
[`nvim-treesitter`](https://github.com/nvim-treesitter/nvim-treesitter), whose
parser management code has been the main reference for this project.

Many thanks to the `nvim-treesitter` maintainers and contributors for the years
of work that made Tree-sitter in Neovim practical and approachable.

## License

MIT. See [LICENSE](LICENSE).
