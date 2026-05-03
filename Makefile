STYLUA ?= stylua
LUACHECK ?= luacheck
NVIM ?= nvim
NVIM_VERSION ?=
DEPDIR ?= .test-deps
CURL ?= curl -fL --create-dirs
TEST_HOME ?= $(CURDIR)/.test-home
TEST_PARSER_HOME ?= $(CURDIR)/.test-parsers

LUA_FILES := lua \
	tests/runner.lua \
	tests/minimal_init.lua \
	tests/install_parsers.lua \
	tests/query_helpers.lua \
	tests/query_helpers_spec.lua \
	tests/query/highlights_spec.lua \
	tests/query/injection_spec.lua

ifeq ($(shell uname -s),Darwin)
  ifeq ($(shell uname -m),arm64)
    NVIM_ARCH ?= macos-arm64
  else
    NVIM_ARCH ?= macos-x86_64
  endif
else
  NVIM_ARCH ?= linux-x86_64
endif

ifneq ($(NVIM_VERSION),)
  NVIM_DIR := $(DEPDIR)/nvim-$(NVIM_VERSION)-$(NVIM_ARCH)
  NVIM_STAMP := $(NVIM_DIR)/.installed
  NVIM_TARBALL := $(NVIM_DIR).tar.gz
  NVIM_URL := https://github.com/neovim/neovim/releases/download/$(NVIM_VERSION)/nvim-$(NVIM_ARCH).tar.gz
  TEST_NVIM := $(NVIM_DIR)/nvim-$(NVIM_ARCH)/bin/nvim
  TEST_NVIM_DEPS := $(NVIM_STAMP)
else
  TEST_NVIM := $(NVIM)
  TEST_NVIM_DEPS :=
endif

.PHONY: format format-check lint doc nvim test-install-parsers test test-verbose check clean

format:
	$(STYLUA) $(LUA_FILES)

format-check:
	$(STYLUA) --check $(LUA_FILES)

lint:
	$(LUACHECK) $(LUA_FILES)

nvim: $(TEST_NVIM_DEPS)

ifneq ($(NVIM_VERSION),)
$(NVIM_STAMP):
	$(CURL) $(NVIM_URL) -o $(NVIM_TARBALL)
	rm -rf $(NVIM_DIR)
	mkdir -p $(NVIM_DIR)
	tar -xf $(NVIM_TARBALL) -C $(NVIM_DIR)
	rm -f $(NVIM_TARBALL)
	touch $@
endif

test-install-parsers: $(TEST_NVIM_DEPS)
	@TS_PACK_TEST_HOME=$(TEST_HOME) TS_PACK_PARSER_TEST_HOME=$(TEST_PARSER_HOME) XDG_CONFIG_HOME=$(TEST_PARSER_HOME)/config XDG_DATA_HOME=$(TEST_PARSER_HOME)/data XDG_CACHE_HOME=$(TEST_PARSER_HOME)/cache XDG_STATE_HOME=$(TEST_PARSER_HOME)/state $(TEST_NVIM) --headless --noplugin -u tests/minimal_init.lua -l tests/install_parsers.lua

test: test-install-parsers
	@TS_PACK_TEST_HOME=$(TEST_HOME) TS_PACK_PARSER_TEST_HOME=$(TEST_PARSER_HOME) XDG_CONFIG_HOME=$(TEST_HOME)/config XDG_DATA_HOME=$(TEST_HOME)/data XDG_CACHE_HOME=$(TEST_HOME)/cache XDG_STATE_HOME=$(TEST_HOME)/state $(TEST_NVIM) --headless --noplugin -u tests/minimal_init.lua -c "lua require('tests.runner').run()" -c qa

test-verbose: test-install-parsers
	@TS_PACK_TEST_HOME=$(TEST_HOME) TS_PACK_PARSER_TEST_HOME=$(TEST_PARSER_HOME) XDG_CONFIG_HOME=$(TEST_HOME)/config XDG_DATA_HOME=$(TEST_HOME)/data XDG_CACHE_HOME=$(TEST_HOME)/cache XDG_STATE_HOME=$(TEST_HOME)/state $(TEST_NVIM) --headless --noplugin -u tests/minimal_init.lua -c "lua require('tests.runner').run({ verbose = true })" -c qa

check: format-check lint test

clean:
	rm -rf $(DEPDIR)
