STYLUA ?= stylua
LUACHECK ?= luacheck
NVIM ?= nvim
TEST_HOME ?= $(CURDIR)/.test-home
TEST_PARSER_HOME ?= $(CURDIR)/.test-parsers
TEST_DEPS ?= $(CURDIR)/.test-deps
HLASSERT ?= $(TEST_DEPS)/highlight-assertions

LUA_FILES := lua test

.PHONY: format format-check lint doc test-install-parsers test test-verbose check clean

format:
	$(STYLUA) $(LUA_FILES)

format-check:
	$(STYLUA) --check $(LUA_FILES)

lint:
	$(LUACHECK) $(LUA_FILES)

$(HLASSERT): test/vendor/highlight-assertions/Cargo.toml test/vendor/highlight-assertions/src/main.rs test/vendor/highlight-assertions/src/parse_assertions.rs
	@mkdir -p $(TEST_DEPS)
	cargo build --manifest-path test/vendor/highlight-assertions/Cargo.toml --release
	cp test/vendor/highlight-assertions/target/release/highlight-assertions $(HLASSERT)

test-install-parsers: $(HLASSERT)
	@TS_PACK_TEST_HOME=$(TEST_HOME) TS_PACK_PARSER_TEST_HOME=$(TEST_PARSER_HOME) HLASSERT=$(HLASSERT) XDG_CONFIG_HOME=$(TEST_PARSER_HOME)/config XDG_DATA_HOME=$(TEST_PARSER_HOME)/data XDG_CACHE_HOME=$(TEST_PARSER_HOME)/cache XDG_STATE_HOME=$(TEST_PARSER_HOME)/state $(NVIM) --headless --noplugin -u test/minimal_init.lua -l test/install_parsers.lua

test: test-install-parsers
	@TS_PACK_TEST_HOME=$(TEST_HOME) TS_PACK_PARSER_TEST_HOME=$(TEST_PARSER_HOME) HLASSERT=$(HLASSERT) XDG_CONFIG_HOME=$(TEST_HOME)/config XDG_DATA_HOME=$(TEST_HOME)/data XDG_CACHE_HOME=$(TEST_HOME)/cache XDG_STATE_HOME=$(TEST_HOME)/state $(NVIM) --headless --noplugin -u test/minimal_init.lua -c "lua require('test.runner').run()" -c qa

test-verbose: test-install-parsers
	@TS_PACK_TEST_HOME=$(TEST_HOME) TS_PACK_PARSER_TEST_HOME=$(TEST_PARSER_HOME) HLASSERT=$(HLASSERT) XDG_CONFIG_HOME=$(TEST_HOME)/config XDG_DATA_HOME=$(TEST_HOME)/data XDG_CACHE_HOME=$(TEST_HOME)/cache XDG_STATE_HOME=$(TEST_HOME)/state $(NVIM) --headless --noplugin -u test/minimal_init.lua -c "lua require('test.runner').run({ verbose = true })" -c qa

check: format-check lint test
