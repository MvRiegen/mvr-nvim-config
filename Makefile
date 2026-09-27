MASON_BIN := $(HOME)/.local/share/nvim/mason/bin

# Prefer tools on PATH (CI image), fall back to local installs.
NVIM ?= nvim
LUACHECK ?= $(or $(shell command -v luacheck),$(wildcard $(HOME)/.luarocks/bin/luacheck),$(MASON_BIN)/luacheck)
LUALS ?= $(or $(shell command -v lua-language-server),$(MASON_BIN)/lua-language-server)

MINIMAL_INIT := tests/minimal_init.lua

.PHONY: all test lint luals

all: lint luals test

test:
	$(NVIM) --headless -u $(MINIMAL_INIT) -c "PlenaryBustedDirectory tests/unit { minimal_init = '$(MINIMAL_INIT)' }"

lint:
	$(LUACHECK) lua/ tests/ --config .luacheckrc

luals:
	$(LUALS) --check . --checklevel=Warning --configpath=.luarc.json
