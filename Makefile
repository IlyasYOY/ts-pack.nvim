.DEFAULT_GOAL := help

STYLUA ?= stylua
LUACHECK ?= luacheck
NVIM ?= nvim
NVIM_VERSION ?=
DEPDIR ?= .test-deps
CURL ?= curl -fL --retry 5 --retry-delay 5 --retry-connrefused --create-dirs
TEST_HOME ?= $(CURDIR)/.test-home
TEST_PARSER_HOME ?= $(CURDIR)/.test-parsers
TEST_WORK ?= $(CURDIR)/.test-work
TEST_HELP_DIR := $(TEST_WORK)/help/doc
TEST_ENV := TS_PACK_TEST_HOME=$(TEST_HOME) TS_PACK_PARSER_TEST_HOME=$(TEST_PARSER_HOME) TS_PACK_TEST_WORK=$(TEST_WORK)/fixtures NVIM_LOG_FILE=$(TEST_WORK)/nvim.log
DOC_FILE := doc/ts-pack.txt

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

.PHONY: all help format format-check lint_stylua lint_luacheck lint nvim test-install-parsers test test-verbose help-tags help-check check clean

all: help

help:
	@printf '%s\n' \
		'ts-pack.nvim development targets:' \
		'  make test                  Install fixtures and run all phases' \
		'  make test-verbose          Show successful test cases' \
		'  make test-install-parsers  Prepare parser/query fixtures' \
		'  make format                Format maintained Lua files' \
		'  make lint                  Run Luacheck and StyLua checks' \
		'  make help-check            Verify tracked Vim help tags' \
		'  make check                 Run the canonical non-mutating checks' \
		'  make clean                 Remove local test artifacts'

format:
	$(STYLUA) $(LUA_FILES)

format-check:
	$(STYLUA) --check $(LUA_FILES)

lint_stylua: format-check

lint_luacheck:
	$(LUACHECK) $(LUA_FILES)

lint: lint_luacheck lint_stylua

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
	@mkdir -p $(TEST_WORK)
	@$(TEST_ENV) XDG_CONFIG_HOME=$(TEST_PARSER_HOME)/config XDG_DATA_HOME=$(TEST_PARSER_HOME)/data XDG_CACHE_HOME=$(TEST_PARSER_HOME)/cache XDG_STATE_HOME=$(TEST_PARSER_HOME)/state $(TEST_NVIM) --headless --noplugin -i NONE -n -u tests/minimal_init.lua -l tests/install_parsers.lua

test: test-install-parsers
	@$(TEST_ENV) XDG_CONFIG_HOME=$(TEST_HOME)/config XDG_DATA_HOME=$(TEST_HOME)/data XDG_CACHE_HOME=$(TEST_HOME)/cache XDG_STATE_HOME=$(TEST_HOME)/state $(TEST_NVIM) --headless --noplugin -i NONE -n -u tests/minimal_init.lua -c "lua require('tests.runner').run()" -c qa

test-verbose: test-install-parsers
	@$(TEST_ENV) XDG_CONFIG_HOME=$(TEST_HOME)/config XDG_DATA_HOME=$(TEST_HOME)/data XDG_CACHE_HOME=$(TEST_HOME)/cache XDG_STATE_HOME=$(TEST_HOME)/state $(TEST_NVIM) --headless --noplugin -i NONE -n -u tests/minimal_init.lua -c "lua require('tests.runner').run({ verbose = true })" -c qa

help-tags: $(TEST_NVIM_DEPS)
	@mkdir -p $(TEST_WORK)
	@$(TEST_ENV) $(TEST_NVIM) --headless --clean -u NONE -i NONE -n -c "helptags doc" -c qa

help-check: $(TEST_NVIM_DEPS)
	@rm -rf $(TEST_HELP_DIR)
	@mkdir -p $(TEST_HELP_DIR)
	@cp $(DOC_FILE) $(TEST_HELP_DIR)/
	@$(TEST_ENV) $(TEST_NVIM) --headless --clean -u NONE -i NONE -n -c "helptags $(TEST_HELP_DIR)" -c qa
	@cmp -s doc/tags $(TEST_HELP_DIR)/tags || { echo 'doc/tags is stale; run make help-tags'; exit 1; }

check: lint test help-check

clean:
	rm -rf $(DEPDIR) $(TEST_HOME) $(TEST_PARSER_HOME) $(TEST_WORK)
