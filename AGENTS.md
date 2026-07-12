# Repository Guidelines

## Project Structure & Module Organization

`ts-pack.nvim` is a Lua-only Neovim plugin for Tree-sitter parser management. Runtime code lives in `lua/ts-pack/`; `init.lua` exposes the public API, while focused modules such as `install.lua`, `spec.lua`, `fs.lua`, `git.lua`, `process.lua`, `path.lua`, `build.lua`, `hooks.lua`, `health.lua`, `indent.lua`, `library.lua`, `queries.lua`, and `report.lua` hold implementation details. Bundled query files live under `lua/ts-pack/bundled_queries/`. Unit tests are colocated as `lua/ts-pack/*_spec.lua`. Fixture-based query and indentation specs live under `tests/query/` and `tests/indent/`; they are loaded through `tests/runner.lua`, with startup setup in `tests/minimal_init.lua`. User-facing API and behavior notes belong in `README.md`.

## Build, Test, and Development Commands

- `make format`: run StyLua over runtime Lua and the harness/query test Lua files listed in `LUA_FILES`.
- `make format-check`: verify formatting without rewriting files.
- `make lint`: run Luacheck with the repository `.luacheckrc`.
- `make lint_luacheck`: run Luacheck only.
- `make lint_stylua`: run StyLua in check mode.
- `make test-install-parsers`: install required parser fixtures under `.test-parsers` and materialize bundled queries for query and indentation tests.
- `make test`: run the headless Neovim test harness with isolated XDG paths
  under `.test-home` and scratch fixtures and logs under `.test-work`.
- `make test-verbose`: run the same harness while printing each successful test.
- `make check`: run formatting checks, lint, tests, and Vim help validation;
  use this as the main regression gate before handing off changes.
- `make help-check`: verify `doc/ts-pack.txt` and tracked `doc/tags` agree.
- `make clean`: remove downloaded Neovim, parser, and scratch test artifacts.

Required local tools are `nvim`, `stylua`, and `luacheck`. Parser installation and fixture tests also need `git`, the `tree-sitter` CLI, and working C/C++ compilers available as `CC`/`cc` and `CXX`/`c++`. Set `NVIM_VERSION` to have the Makefile download a specific Neovim release into `.test-deps`, or set `NVIM` to run tests with an explicit local binary.
Required stable verification versions are v0.11.7 and v0.12.4; nightly is a
non-blocking compatibility probe in CI.

## Coding Style & Naming Conventions

Use two-space indentation, LF line endings, and a final newline, matching `.editorconfig`. Lua formatting is controlled by `.stylua.toml`: 100-column width, single quotes when possible, and explicit call parentheses. Keep modules small and named after their responsibility. Prefer local helper functions, `vim.validate` for public input checks, and `vim.fs.joinpath` for paths. Public API names should remain aligned with `vim.pack` where applicable: `add`, `update`, `del`, and `get`.

## Testing Guidelines

Add or update `*_spec.lua` files beside the module under test. Fixture specs for bundled query and indentation behavior live under `tests/query/` and `tests/indent/`, and are loaded by `tests/runner.lua`. The harness provides `describe`, `it`, `before_each`, `after_each`, and `assert.*`; keep tests deterministic and isolated through the existing reset helpers. For lockfile or report formatting changes, assert exact serialized output where practical instead of only round-tripping decoded data. Run `make check` after behavior changes.

Name test groups so runner output includes the module or public surface under test, for example `describe('ts-pack.report', ...)` or `describe('ts-pack.query_highlights', ...)`, rather than generic labels such as `bundled highlight queries`.

## Commit & Pull Request Guidelines

Recent history uses concise Conventional Commit prefixes such as `feat:`, `fix:`, `refactor:`, `docs:`, and `ci:`. Keep commits narrowly scoped and do not mix unrelated refactors with behavior changes. Pull requests should describe the user-visible change, note any lockfile or async behavior implications, link relevant issues, and include the verification command output, usually `make check`.

## Agent-Specific Instructions

Do not make commits unless explicitly asked. Explain what changed, why it changed, and how it was verified.
Keep README and `doc/ts-pack.txt` aligned, and run `make help-tags` after help
tag changes. Releases are manual through `.github/workflows/release.yml`; do
not create or push tags unless explicitly requested.
