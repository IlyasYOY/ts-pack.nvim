# ts-pack.nvim plan

## Summary

`ts-pack.nvim` should be a parser-only manager for Neovim Tree-sitter parsers. It should feel similar to `vim.pack`: declarative API, persistent lockfile, `add/get/update/del` flow, and review-before-apply updates. For v1, the scope stays narrow: manage parser libraries and parser-adjacent query directories when they are explicitly declared by the registry. Do not grow this into `nvim-treesitter` feature management such as highlighting modules, textobjects, autotag, or user-facing configuration helpers.

The chosen model is a hybrid registry. `ts-pack` ships with a built-in parser registry, but users can override or extend it in `setup({ registry = ... })`. This keeps the common path simple while still allowing custom grammars and local parser repos.

## Public API

Expose `require('ts_pack').setup(opts)`, `add(names, opts)`, `get(names?, opts)`, `update(names?, opts)`, and `del(names, opts)`.

In v1, `add()` should accept parser names, not fully inline parser specs. Custom grammars should be added through registry overrides in `setup()`, not ad-hoc arguments on every call.

`setup()` should own the install root, lockfile path, confirmation defaults, concurrency defaults, and registry overrides.

`get()` should return structured parser information in the shape `{ name, active, path, queries_path?, rev, spec }`, where `active` means the parser was declared via `add()` in the current session.

`update()` should compute target revisions either from the registry or from the lockfile, then open a pack-like review buffer. Applying the update should happen on `:write`, and cancelling it should happen on `:quit`.

## Persistent state and runtime layout

The managed install root should live under `stdpath('data')` in a dedicated runtime directory that `ts-pack` adds to `runtimepath`. Inside that root, manage:

- `parser/`
- `queries/`
- `parser-info/`

The default lockfile path should be `stdpath('config') .. '/ts-pack-lock.json'`.

Runtime behavior should follow Neovim’s Tree-sitter contract from `treesitter.txt`: install parsers as shared libraries under `parser/<lang>.so`, manage query directories under `queries/<lang>/` when present, and make the parser available in the same session via `vim.treesitter.language.add(name)`. Use the bare parser name, not `tree_sitter_<lang>`.

## Registry model

The built-in registry should live in `ts-pack`’s own internal format and initially be seeded from local `nvim-treesitter` metadata where that reduces bootstrapping work.

Registry entries should support:

- `src`
- `revision`
- `version?`
- `location?`
- `queries?`
- `generate?`
- `symbol_name?`
- `path?`

User registry overrides should be merged on top of the built-in registry in `setup()`.

## Internal module breakdown

Normalize the plugin layout around `lua/ts_pack/*`, add `plugin/ts_pack.lua`, and replace the current minimal bootstrap stub with the real entrypoint structure.

Split implementation into focused modules:

- `config.lua`
- `registry.lua`
- `lockfile.lua`
- `state.lua`
- `runtime.lua`
- `git.lua`
- `build.lua`
- `install.lua`
- `planner.lua`
- `review.lua`
- `commands.lua`
- `health.lua`

Module responsibilities:

- `registry.lua` holds the built-in parser table plus merged user overrides.
- `lockfile.lua` reads, writes, validates, and repairs `ts-pack-lock.json`.
- `state.lua` tracks current-session active parsers.
- `runtime.lua` owns `runtimepath` injection, parser loading, and query wiring.
- `git.lua` handles fetch and source update operations.
- `build.lua` handles grammar generation and parser build steps.
- `planner.lua` contains pure decision logic for install, update, and delete actions.
- `install.lua` performs the side effects for install, update, and delete flows.
- `review.lua` implements the confirmation buffer and the review UX.
- `commands.lua` exposes the user command layer.
- `health.lua` provides environment and state diagnostics.

## User-facing behavior

Expose thin user commands such as `:TSPackUpdate`, `:TSPackDelete`, and `:TSPackStatus`.

The UX should stay close to `vim.pack` at the workflow level, not necessarily at the implementation-detail level. That means:

- declarative add flow
- persistent lockfile
- review-before-apply update flow
- explicit delete flow

For v1, skip `vim.pack`’s embedded LSP extras inside the review buffer. A simpler review buffer with clear pending changes and apply/cancel behavior is enough.

## Documentation

Add `doc/ts-pack.txt` and document:

- the pack-like lifecycle
- lockfile behavior
- registry overrides
- the narrow parser-only scope
- the fact that `ts-pack` is independent from `nvim-treesitter` feature modules

## Testing strategy

Keep tests out of `lua/`.

Use split suites:

- `spec/ts_pack/*` for pure-Lua unit tests
- `tests/ts_pack/*_spec.lua` for headless Neovim integration tests

Unit tests should cover spec normalization, registry merge precedence, lockfile read/write/repair behavior, planner decisions, and runtime path calculation.

Integration tests should cover fresh install flow, update accept flow, update cancel flow, delete flow, same-session parser availability after `add()`, and local-path custom grammars via registry override.

The integration harness should use isolated `XDG_CONFIG_HOME` and `XDG_DATA_HOME` per scenario, local git grammar fixtures, and no network dependency.

Verification should eventually be organized around:

- `make test-unit`
- `make test-integration`
- `make test`
- `make check`

## Scope guardrails

“Similar to `vim.pack`” should mean similarity of API shape and workflow, not full parity with `vim.pack` internals.

`ts-pack` should stay independent from `nvim-treesitter` commands and feature modules. Reuse ideas from `nvim-treesitter` only where they reduce parser-manager implementation risk, especially around registry/build/install behavior.
