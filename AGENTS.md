# Repository Guidelines

## Project Structure & Module Organization

`ts-pack.nvim` is a Lua-only Neovim plugin for Tree-sitter parser management. Runtime code lives in `lua/ts-pack/`; `init.lua` exposes the public API, while focused modules such as `install.lua`, `spec.lua`, `fs.lua`, `git.lua`, `process.lua`, `path.lua`, `build.lua`, `hooks.lua`, `indent.lua`, `library.lua`, `queries.lua`, and `report.lua` hold implementation details. Unit tests are colocated as `lua/ts-pack/*_spec.lua`. Fixture-based query and indentation specs are loaded through `test/runner.lua`, with startup setup in `test/minimal_init.lua`. User-facing API and behavior notes belong in `README.md`.

## Build, Test, and Development Commands

- `make format`: run StyLua over `lua/` and `test/`.
- `make format-check`: verify formatting without rewriting files.
- `make lint`: run Luacheck with the repository `.luacheckrc`.
- `make test-install-parsers`: build the vendored `highlight-assertions` helper and install parser fixtures for query and indentation tests.
- `make test`: run the headless Neovim test harness with isolated XDG paths under `.test-home`.
- `make test-verbose`: run the same harness while printing each successful test.
- `make check`: run formatting, lint, and tests; use this as the main regression gate before handing off changes.

Required local tools are `nvim`, `stylua`, and `luacheck`. The tests create temporary parser git repositories and build the vendored `highlight-assertions` helper, so `git` and `cargo` must also be available.

## Coding Style & Naming Conventions

Use two-space indentation, LF line endings, and a final newline, matching `.editorconfig`. Lua formatting is controlled by `.stylua.toml`: 100-column width, single quotes when possible, and explicit call parentheses. Keep modules small and named after their responsibility. Prefer local helper functions, `vim.validate` for public input checks, and `vim.fs.joinpath` for paths. Public API names should remain aligned with `vim.pack` where applicable: `add`, `update`, `del`, and `get`.

## Testing Guidelines

Add or update `*_spec.lua` files beside the module under test. Fixture specs for bundled query and indentation behavior live under the parser fixture tree loaded by `test/runner.lua`. The harness provides `describe`, `it`, `before_each`, `after_each`, and `assert.*`; keep tests deterministic and isolated through the existing reset helpers. For lockfile or report formatting changes, assert exact serialized output where practical instead of only round-tripping decoded data. Run `make check` after behavior changes.

Name test groups so runner output includes the module or public surface under test, for example `describe('ts-pack.report', ...)` or `describe('ts-pack.query_highlights', ...)`, rather than generic labels such as `bundled highlight queries`.

## Commit & Pull Request Guidelines

Recent history uses concise Conventional Commit prefixes such as `feat:`, `fix:`, `refactor:`, `docs:`, and `ci:`. Keep commits narrowly scoped and do not mix unrelated refactors with behavior changes. Pull requests should describe the user-visible change, note any lockfile or async behavior implications, link relevant issues, and include the verification command output, usually `make check`.

## Agent-Specific Instructions

Do not make commits unless explicitly asked. Explain what changed, why it changed, and how it was verified.
