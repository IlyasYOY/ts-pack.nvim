STYLUA ?= stylua
LUACHECK ?= luacheck
NVIM ?= nvim

LUA_FILES := lua test
TEST_ENV := XDG_CONFIG_HOME=$(CURDIR)/.testdata/config \
	XDG_DATA_HOME=$(CURDIR)/.testdata/data \
	XDG_STATE_HOME=$(CURDIR)/.testdata/state \
	XDG_CACHE_HOME=$(CURDIR)/.testdata/cache
TEST_CMD := $(TEST_ENV) $(NVIM) --headless --clean -u test/minimal_init.lua -l test/runner.lua

.PHONY: format format-check lint doc test test-unit check clean

format:
	$(STYLUA) $(LUA_FILES)

format-check:
	$(STYLUA) --check $(LUA_FILES)

lint:
	$(LUACHECK) $(LUA_FILES)

test:
	@$(TEST_CMD)

test-unit: test

check: format-check lint test
