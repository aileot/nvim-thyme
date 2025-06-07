SHELL := bash
.ONESHELL:
.DELETE_ON_ERROR:

MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --warn-undefined-variables

ROOT_MODNAME ?= thyme

FENNEL ?= fennel
VUSTED ?= vusted

# Note: The --correlate flag is likely to cause conflicts.
FNL_FLAGS ?=
FNL_SPEC_FLAGS ?= --correlate

REPO_ROOT:=$(abspath $(dir $(lastword $(MAKEFILE_LIST))))

SCRIPT_ROOT:=$(REPO_ROOT)/scripts
SCRIPT_WRITE_PCALLABLES := $(SCRIPT_ROOT)/write-pcallables

TEST_ROOT:=$(REPO_ROOT)/test
TEST_CONTEXT_DIR:=$(TEST_ROOT)/context
TEST_HELPER_DIR:=$(TEST_ROOT)/helper
TEST_PREREQUISITES:=$(TEST_HELPER_DIR)/prerequisites.lua

FNL_SPECS:=$(wildcard $(TEST_ROOT)/*_spec.fnl)
LUA_SPECS:=$(FNL_SPECS:%.fnl=%.lua)
LUA_ALL_SPECS:=$(wildcard $(TEST_ROOT)/*_spec.lua)
LUA_OLD_SPECS:=$(filter-out $(LUA_SPECS),$(LUA_ALL_SPECS))
TEST_DEPS:=$(wildcard $(TEST_ROOT)/*/*.fnl)
TEST_DEPS+=$(wildcard $(TEST_ROOT)/*/*.lua)

LUA_ALL:=$(wildcard lua/*/*.lua)
LUA_ALL+=$(wildcard lua/*/*/*.lua)
LUA_ALL+=$(wildcard lua/*/*/*/*.lua)
FNL_SRC:=$(wildcard fnl/*/*.fnl)
FNL_SRC+=$(wildcard fnl/*/*/*.fnl)
FNL_SRC+=$(wildcard fnl/*/*/*/*.fnl)
FNL_SRC+=$(wildcard fnl/*/*/*/*/*.fnl)
FNL_SRC:=$(filter-out %/macros.fnl,$(FNL_SRC))
LUA_RES:=$(FNL_SRC:fnl/%.fnl=lua/%.lua)
LUA_OLD:=$(filter-out $(LUA_RES),$(LUA_ALL))

FNL_SRC_DIRS:=$(wildcard fnl/*/*/)
FNL_SRC_DIRS+=$(wildcard fnl/*/*/*/)
LUA_RES_DIRS:=$(FNL_SRC_DIRS:fnl/%=lua/%)

REPO_FNL_DIR := $(REPO_ROOT)/fnl
REPO_FNL_PATH := $(REPO_FNL_DIR)/?.fnl;$(REPO_FNL_DIR)/?/init.fnl
REPO_MACRO_DIR := $(REPO_FNL_DIR)
REPO_MACRO_PATH := $(REPO_MACRO_DIR)/?.fnl;$(REPO_MACRO_DIR)/?/init.fnl

FNL_INIT_MOD_FILE:=$(REPO_ROOT)/fnl/$(ROOT_MODNAME)/init.fnl
LUA_INIT_MOD_FILE:=$(FNL_INIT_MOD_FILE:fnl/%.fnl=lua/%.lua)

VUSTED_FLAGS ?= --shuffle --output=utfTerminal --verbose
VUSTED_EXTRA_FLAGS ?=

VUSTED_EXTRA_ARGS ?= -Es
VUSTED_ARGS ?= "--headless --clean $(VUSTED_EXTRA_ARGS)"

.DEFAULT_GOAL := help
.PHONY: help
help: ## Show this help
	@echo Targets:
	@egrep -h '^\S+: .*## \S+' $(MAKEFILE_LIST) | sed 's/: .*##/:/' | column -t -s ':' | sed 's/^/  /'

# NOTE: In addition to the `mkdir` in `lua/%.lua`, this directory recipee is
# still necessary in some cases.
lua/%/:
	@mkdir -p $@

lua/%.lua: fnl/%.fnl
	@mkdir -p $(dir $@)
	@$(FENNEL) \
		$(FNL_FLAGS) \
		--add-macro-path "$(REPO_MACRO_PATH)" \
		--compile $< > $@
	@echo $< "	->	" $@

.PHONY: clean
clean: ## Remove generated files
	@rm -rf lua/
	@rm -f $(LUA_ALL_SPECS)
	@rm -rf $(TEST_CONTEXT_DIR)

.PHONY: prune
prune: ## Remove stale lua files
	@if [ -n "$(LUA_OLD)" ]; then
	@	rm $(LUA_OLD) && echo "Pruned $(LUA_OLD)"
	@fi
	@if [ -n "$(LUA_OLD_SPECS)" ]; then
	@	rm $(LUA_OLD_SPECS) && echo "Pruned $(LUA_OLD_SPECS)"
	@fi

.PHONY: pcallables
pcallables: ## Force to re-generate pcallables
	@$(SCRIPT_WRITE_PCALLABLES)

$(LUA_INIT_MOD_FILE): pcallable # Just to trigger pcallable re-generations as export functions could be changed.

.PHONY: build
build: $(LUA_RES_DIRS) prune $(LUA_RES) ## Compile lua files from fnl/

%_spec.lua: %_spec.fnl $(LUA_RES) $(TEST_DEPS)
	@$(FENNEL) \
		$(FNL_SPEC_FLAGS) \
		--add-macro-path "$(REPO_MACRO_PATH);$(REPO_ROOT)/?.fnl" \
		--add-fennel-path "$(REPO_ROOT)/?.fnl" \
		--add-package-path "$(REPO_ROOT)/?.lua" \
		--correlate \
		--compile $< > $@
	@echo $< "	->	" $@

.PHONY: test
test: build $(LUA_SPECS) ## Run test
	@REPO_ROOT="$(REPO_ROOT)" \
		THYME_DEBUG=1 \
		FNL_DIR=lua \
		DEPS_DIR="$(TEST_CONTEXT_DIR)/.deps" \
		XDG_CONFIG_HOME="$(TEST_CONTEXT_DIR)/.config" \
		XDG_CACHE_HOME="$(TEST_CONTEXT_DIR)/.cache" \
		XDG_DATA_HOME="$(TEST_CONTEXT_DIR)/.data" \
		XDG_STATE_HOME="$(TEST_CONTEXT_DIR)/.state" \
		VUSTED_ARGS=$(VUSTED_ARGS) \
		$(VUSTED) \
		--helper $(TEST_PREREQUISITES) \
		$(VUSTED_FLAGS) \
		$(VUSTED_EXTRA_FLAGS) \
		$(REPO_ROOT)
