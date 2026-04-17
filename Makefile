STYLUA ?= stylua
LUACHECK ?= luacheck
NVIM ?= nvim

LUA_FILES := lua plugin

.PHONY: format format-check lint doc test check clean

format:
	$(STYLUA) $(LUA_FILES)

format-check:
	$(STYLUA) --check $(LUA_FILES)

lint:
	$(LUACHECK) $(LUA_FILES)

check: format-check lint
