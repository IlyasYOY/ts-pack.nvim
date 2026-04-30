# ts-pack.nvim

Lua-only Tree-sitter parser management for Neovim, shaped after `vim.pack`.

`ts-pack.nvim` does not ship parser specs, parser binaries, user commands, or
`plugin/` startup files. Call the Lua API with complete parser specs:

```lua
local ts_pack = require('ts-pack')

ts_pack.add({
  {
    src = 'https://github.com/tree-sitter/tree-sitter-lua',
    name = 'lua',
    version = 'main',

    -- Optional parser build fields.
    location = nil,
    path = nil,
    queries = nil,
    generate = nil,
    generate_from_json = nil,
  },
})
```

## API

```lua
require('ts-pack').add(specs, opts)
require('ts-pack').update(names, opts)
require('ts-pack').del(names, opts)
require('ts-pack').get(names, opts)
```

`specs` is always a list. `name` defaults to the repository basename with a
leading `tree-sitter-` stripped. `names` is an optional list of parser names; if
omitted, the active parsers from the current session are used.

Supported options follow `vim.pack` naming where they apply:

- `offline = true` prevents git clone/fetch.
- `target = 'version'` installs the spec `version`.
- `target = 'lockfile'` restores the lockfile revision.
- `info = false` keeps `get()` from reading extra lockfile/install metadata.
- `async = true` registers the specs immediately and installs missing parsers in
  a coroutine, yielding around clone/fetch/build subprocesses so startup does not
  wait for parser installation.

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
