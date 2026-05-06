# ts-pack.nvim

Lua-only Tree-sitter parser management for Neovim, shaped after `vim.pack`.

## Acknowledgements

`ts-pack.nvim` is mainly a fork of
[`nvim-treesitter`](https://github.com/nvim-treesitter/nvim-treesitter)'s parser
and query management pieces, reduced to a Lua-only API shaped after `vim.pack`.
It keeps the parser registry, bundled queries, dependency expansion, install
flow, indentation engine, and health-reporting ideas, while intentionally
leaving out the startup plugin layer, user commands, tiered language UX, and
install log UI.

Many thanks to the `nvim-treesitter` maintainers and contributors for the years
of work that made Tree-sitter in Neovim practical and approachable.

## Usage

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
    bundled_queries = nil,
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

## Setup

Install `ts-pack.nvim` with your plugin manager, then keep your parser list in
the same startup config. `add()` registers parser metadata immediately and
installs missing parser artifacts; pass `async = true` if you want installation
to continue in the background after startup.

With `lazy.nvim`:

```lua
return {
  {
    'IlyasYOY/ts-pack.nvim',
    lazy = false,
    config = function()
      local ts_pack = require('ts-pack')
      local library = require('ts-pack.library')

      ts_pack.setup({
        -- Optional: limit concurrent parser installs.
        install_jobs = nil,
      })

      ts_pack.add(library.select({
        'lua',
        'vim',
        'vimdoc',
        'query',
        'markdown',
        'markdown_inline',
      }), { async = true })
    end,
  },
}
```

With Neovim's built-in `vim.pack`:

```lua
vim.pack.add({
  { src = 'https://github.com/IlyasYOY/ts-pack.nvim' },
})

local ts_pack = require('ts-pack')
local library = require('ts-pack.library')

ts_pack.setup({
  -- Optional: limit concurrent parser installs.
  install_jobs = nil,
})

ts_pack.add(library.select({
  'lua',
  'vim',
  'vimdoc',
  'query',
  'markdown',
  'markdown_inline',
}), { async = true })
```

The examples use `library.select()` so parser dependencies and bundled queries
are selected together. For custom parsers, pass full specs to `ts_pack.add()`
instead.

## API

```lua
require('ts-pack').setup(opts)
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
For a small imported set, library-selected specs also install bundled
`nvim-treesitter` queries alongside the parser. These bundled queries are scoped
to `library.select()` output only; hand-written specs do not receive them unless
they set `bundled_queries` explicitly.

See [docs/library.md](docs/library.md) for the complete parser registry
reference.

`queries` copies a query directory from the parser checkout. A string path keeps
the directory unchanged, including nested files. A table copies only enabled
top-level `.scm` query types:

```lua
ts_pack.add({
  {
    src = 'https://github.com/tree-sitter/tree-sitter-lua',
    name = 'lua',
    queries = {
      path = 'queries/lua',
      filter = { highlights = true, indents = true },
    },
  },
})
```

`bundled_queries = true` copies all bundled `.scm` files available for the
parser, while a table copies only enabled bundled query types:

```lua
ts_pack.add({
  {
    src = 'https://github.com/tree-sitter/tree-sitter-lua',
    name = 'lua',
    bundled_queries = { highlights = true, indents = true },
  },
})
```

False table entries and unknown query types are ignored. Empty filter tables
install no query `.scm` files and remove stale files for that parser.

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

## Tree-sitter features

`ts-pack` installs parser binaries and query files. It does not automatically
enable Tree-sitter features for buffers. After parsers and matching queries are
installed, enable the Neovim features you want from an `ftplugin` or `FileType`
autocommand.

Enable Tree-sitter highlighting with Neovim's built-in highlighter:

```lua
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'lua', 'vim', 'help', 'query', 'markdown' },
  callback = function(ev)
    vim.treesitter.start(ev.buf)
  end,
})
```

Enable Tree-sitter indentation with the `ts-pack` indentation engine. The parser
must have an `indents.scm` query, either from bundled queries selected by
`library.select()` or from a custom spec with `queries` or `bundled_queries`:

```lua
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'lua' },
  callback = function(ev)
    vim.bo[ev.buf].indentexpr = "v:lua.require'ts-pack.indent'.expr()"
  end,
})
```

Enable Tree-sitter folds with Neovim's built-in `foldexpr`. Each parser needs a
matching `folds.scm` query:

```lua
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'lua', 'vim', 'query', 'markdown' },
  callback = function(ev)
    vim.wo.foldmethod = 'expr'
    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
  end,
})
```

## Health checks

Run `:checkhealth ts-pack` to inspect the parser and query artifacts managed by
`ts-pack`.

The report includes Neovim and Tree-sitter ABI details; installer toolchain
checks for `git`, `tree-sitter`, `CC`/`cc`, and `CXX`/`c++`; parser, parser-info,
query, cache, and lockfile path writability; installed parser binaries; active
parsers registered in the current session; lockfile entries; local parser
revisions; and the query files materialized under `stdpath('data')/site/queries`.
It parses managed query files when the matching parser can be loaded. It also
lists all Tree-sitter queries visible on `runtimepath` in a separate section, so
queries provided by Neovim or other plugins are not confused with files managed
by `ts-pack`.

A warning for a local revision that differs from the lockfile means the parser
binary on disk was not built from the revision recorded in
`ts-pack-lock.json`. Run `update({ name }, { target = 'lockfile' })` to restore
the locked revision, or update without `target = 'lockfile'` to refresh the
lockfile.

## Options

Supported options follow `vim.pack` naming where they apply:

- `setup({ install_jobs = n })` limits parser install concurrency to `n`
  workers. When unset, installs keep using the host parallelism reported by
  libuv, capped to the number of pending parsers.
- `offline = true` prevents git clone/fetch.
- `target = 'version'` installs the spec `version`.
  When `version` is unset and `branch` is set, it installs `origin/<branch>`.
- `target = 'lockfile'` restores the lockfile revision.
- `info = false` keeps `get()` from reading extra lockfile/install metadata.
- `async = true` registers the specs immediately and installs missing parsers in
  a coroutine when passed to `add()`. It updates active parsers in a coroutine
  when passed to `update()`. Both paths yield around clone/fetch/build
  subprocesses so startup does not wait for parser installation.
- `quiet = true` hides install progress and installed-parser summaries while
  preserving warnings and errors.

Parser artifacts are installed under `stdpath('data')/site`:

- `parser/<name>.so`
- `parser-info/<name>.revision`
- `queries/<name>/` when `spec.queries` is provided or a library-selected parser
  has bundled queries. Filtered query tables may create only selected `.scm`
  files, and empty filters leave no query files installed.

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

## Development

Run the test suite with the current `nvim` from your `PATH`:

```sh
make test
```

To try another Neovim release, set `NVIM_VERSION`. The requested release is
downloaded into `.test-deps` and reused on later runs:

```sh
make test NVIM_VERSION=nightly
make test NVIM_VERSION=stable
make test NVIM_VERSION=v0.11.4
```

Run `make clean` to remove downloaded test dependencies and force a fresh
download on the next versioned run.

You can still run the tests with an explicit local binary when `NVIM_VERSION` is
unset:

```sh
make test NVIM=/path/to/nvim
```

## License

MIT. See [LICENSE](LICENSE).
