SHELL := bash
.ONESHELL:
.DELETE_ON_ERROR:

MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --warn-undefined-variables

FENNEL ?= fennel
VUSTED ?= vusted

# Note: The --correlate flag is likely to cause conflicts.
FNL_FLAGS ?=
FNL_EXTRA_FLAGS ?=

VUSTED_FLAGS ?= --shuffle --output=utfTerminal
VUSTED_EXTRA_FLAGS ?=

REPO_ROOT:=$(abspath $(dir $(lastword $(MAKEFILE_LIST))))
TEST_ROOT:=$(REPO_ROOT)/test
TEST_CONTEXT_DIR:=$(TEST_ROOT)/context

FNL_SPECS:=$(wildcard $(TEST_ROOT)/*_spec.fnl)
LUA_SPECS:=$(FNL_SPECS:%.fnl=%.lua)
LUA_ALL_SPECS:=$(wildcard $(TEST_ROOT)/*_spec.lua)
TEST_DEPS:=$(wildcard $(TEST_ROOT)/*/*.fnl)
TEST_DEPS+=$(wildcard $(TEST_ROOT)/*/*.lua)

FNL_SRC_DIR=fnl

FNL_SRC:=$(wildcard $(FNL_SRC_DIR)/*/*.fnl)
FNL_SRC+=$(wildcard $(FNL_SRC_DIR)/*/*/*.fnl)
FNL_SRC:=$(filter-out %/macros.fnl,$(FNL_SRC))
LUA_RES:=$(FNL_SRC:$(FNL_SRC_DIR)/%.fnl=lua/%.lua)

FNL_SRC_DIRS:=$(wildcard $(FNL_SRC_DIR)/*/*/)
LUA_RES_DIRS:=$(FNL_SRC_DIRS:$(FNL_SRC_DIR)/%=lua/%)

REPO_FNL_DIR := $(REPO_ROOT)/$(FNL_SRC_DIR)
REPO_FNL_PATH := $(REPO_FNL_DIR)/?.fnl;$(REPO_FNL_DIR)/?/init.fnl
REPO_MACRO_DIR := $(REPO_FNL_DIR)
REPO_MACRO_PATH := $(REPO_MACRO_DIR)/?.fnl;$(REPO_MACRO_DIR)/?/init.fnl

.DEFAULT_GOAL := help
.PHONY: help
help: ## Show this help
	@echo
	@echo 'Usage:'
	@echo '  make <target> [flags...]'
	@echo
	@echo 'Targets:'
	@egrep -h '^\S+: .*## \S+' $(MAKEFILE_LIST) | sed 's/: .*##/:/' | column -t -c 2 -s ':' | sed 's/^/  /'
	@echo

lua/%/:
	@mkdir -p $@

lua/%.lua: $(FNL_SRC_DIR)/%.fnl
	@$(FENNEL) \
		$(FNL_FLAGS) \
		$(FNL_EXTRA_FLAGS) \
		--add-macro-path "$(REPO_MACRO_PATH)" \
		--compile $< > $@
	@echo $< "	->	" $@

.PHONY: clean
clean:
	@rm -rf lua/
	@rm -f $(LUA_ALL_SPECS)
	@rm -rf $(TEST_CONTEXT_DIR)

.PHONY: build
build: $(LUA_RES_DIRS) $(LUA_RES)

%_spec.lua: %_spec.fnl $(LUA_RES) $(TEST_DEPS) ## Compile fnl spec file into lua
	@$(FENNEL) \
		$(FNL_FLAGS) \
		$(FNL_EXTRA_FLAGS) \
		--add-macro-path "$(REPO_MACRO_PATH);$(REPO_ROOT)/?.fnl" \
		--add-fennel-path "$(REPO_ROOT)/?.fnl" \
		--add-package-path "$(REPO_ROOT)/?.lua" \
		--correlate \
		--compile $< > $@
	@echo $< "	->	" $@

.PHONY: test
test: build $(LUA_SPECS) ## Run test
	@REPO_ROOT="$(REPO_ROOT)" \
		XDG_CONFIG_HOME="$(TEST_CONTEXT_DIR)/.config" \
		XDG_CACHE_HOME="$(TEST_CONTEXT_DIR)/.cache" \
		XDG_DATA_HOME="$(TEST_CONTEXT_DIR)/.data" \
		XDG_STATE_HOME="$(TEST_CONTEXT_DIR)/.state" \
		$(VUSTED) \
		$(VUSTED_FLAGS) \
		$(VUSTED_EXTRA_FLAGS) \
		$(REPO_ROOT)
